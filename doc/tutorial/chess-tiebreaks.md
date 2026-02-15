# Chess Tiebreaks

PGN (Portable Game Notation) is a plain text format for recording chess games.
Each game has metadata in bracketed lines like `[White "LastName, FirstName"]`
followed by the moves. Here we'll parse a tournament's PGN file to find players
who faced each other more than once (indicating tie-break games).

The data comes from the Tata Steel Masters 2024 broadcast on Lichess, the
[tie-break games can be seen
here](https://lichess.org/broadcast/tata-steel-masters-2024/tiebreaks/L43YRQWv#boards).

## The Complete Solution

```mdtest-command
curl -sS https://lichess.org/api/broadcast/ycy5D2r8.pgn |
super -i line -s -c "
  --
  -- parse the pgn file
  --
  where this != ''
  | grok('.*White \"%{WORD:last_name_white}|.*Black \"%{WORD:last_name_black}', this)
  | where not is_error(this)

  --
  -- pair up each player in each game
  --
  -- future super versions will support window functions, but we can make do with this
  --
  | put row_num:=count(this)
  | put game_id:=((row_num - 1) / 2)::int64
  | aggregate
      last_name_white:=max(last_name_white),
      last_name_black:=max(last_name_black)
    by game_id
  | drop game_id

  --
  -- re-organize the data by player and opponent regardless of piece color
  --
  | [
      {player: last_name_white, opponent: last_name_black},
      {player: last_name_black, opponent: last_name_white}
    ]
  | unnest this

  --
  -- count each match-up of player and opponent and find any with counts > 1
  --
  -- this should be players who participated in tie-breaks, as the regular
  -- tournament was only a single round-robin
  --
  | count(this) by player, opponent
  | where count > 1
  | sort player, opponent
" -
```

```mdtest-output
{player:"Abdusattorov",opponent:"Wei",count:3::uint64}
{player:"Giri",opponent:"Gukesh",count:4::uint64}
{player:"Gukesh",opponent:"Giri",count:4::uint64}
{player:"Gukesh",opponent:"Wei",count:3::uint64}
{player:"Wei",opponent:"Abdusattorov",count:3::uint64}
{player:"Wei",opponent:"Gukesh",count:3::uint64}
```

## Walkthrough

### Line Input and Filtering

`-i line` tells super to treat each line as a separate string record. We filter
out empty lines with `where this != ''`.

### Grok Parsing

The grok pattern `'.*White \"%{WORD:last_name_white}|.*Black \"%{WORD:last_name_black}'`
uses alternation (`|`) to match either a White or Black player line. The
`%{WORD:...}` capture extracts just the last name (the first word after the
opening quote).

Lines that don't match (like move notation or other metadata) produce errors,
which we filter with `where not is_error(this)`.

### Pairing Records

PGN files list White and Black players on consecutive lines for each game. We
need to combine them into single records.

The trick is using expression-context `count(this)` which produces a running
count (1, 2, 3, ...). Integer division `(row_num - 1) / 2` maps pairs of rows to
the same game_id: rows 1,2 get game_id 0; rows 3,4 get game_id 1, etc.

Then `aggregate ... by game_id` with `max()` picks up the non-null value from
each field within each pair.

### Reshaping with Arrays and Unnest

Each game record has `{last_name_white, last_name_black}`. To count matchups
regardless of color, we create an array with both perspectives:

```
| [{player: last_name_white, opponent: last_name_black},
   {player: last_name_black, opponent: last_name_white}]
| unnest this
```

This doubles our records — each game now appears twice, once from each player's
perspective.

### Final Aggregation

`count(this) by player, opponent` counts how many times each matchup occurred.
`where count > 1` filters to only matchups that happened more than once -
these are the tie-break games.

## Nested `unnest ... into` Example

Here's a minimal dataset to demonstrate this next technique, based on similar
data we were just working with. Four players in a single round-robin (6 games),
plus one tie-breaker between Gukesh and Wei:

```mdtest-input pairings.sup
{pairing:"Giri Gukesh"}
{pairing:"Giri Wei"}
{pairing:"Giri Abdusattorov"}
{pairing:"Gukesh Wei"}
{pairing:"Gukesh Abdusattorov"}
{pairing:"Wei Abdusattorov"}
{pairing:"Gukesh Wei"}
```

```mdtest-command
super -s -c "
  split(pairing, ' ')
  | unnest {pairing:this, player:this} into (
      unnest {player: this.player, opponent: pairing} into (
        where player != opponent
        | cut player, opponent
      )
    )
" pairings.sup
```

```mdtest-output
{player:"Giri",opponent:"Gukesh"}
{player:"Gukesh",opponent:"Giri"}
{player:"Giri",opponent:"Wei"}
{player:"Wei",opponent:"Giri"}
{player:"Giri",opponent:"Abdusattorov"}
{player:"Abdusattorov",opponent:"Giri"}
{player:"Gukesh",opponent:"Wei"}
{player:"Wei",opponent:"Gukesh"}
{player:"Gukesh",opponent:"Abdusattorov"}
{player:"Abdusattorov",opponent:"Gukesh"}
{player:"Wei",opponent:"Abdusattorov"}
{player:"Abdusattorov",opponent:"Wei"}
{player:"Gukesh",opponent:"Wei"}
{player:"Wei",opponent:"Gukesh"}
```

### How Nested Unnest Works

The `unnest ... into` syntax is powerful but takes some unpacking:

1. **`split(pairing, ' ')`** turns `"Giri Gukesh"` into `["Giri", "Gukesh"]`

2. **First unnest**: `unnest {pairing:this, player:this} into (...)`
   - Keeps the full array as `pairing`
   - Unnests each element as `player`
   - For `["Giri", "Gukesh"]` this produces two records:
     - `{pairing: ["Giri", "Gukesh"], player: "Giri"}`
     - `{pairing: ["Giri", "Gukesh"], player: "Gukesh"}`

3. **Second unnest**: `unnest {player: this.player, opponent: pairing} into (...)`
   - Preserves `player` from the outer record
   - Unnests `pairing` array elements as `opponent`
   - For `{pairing: ["Giri", "Gukesh"], player: "Giri"}` this produces:
     - `{player: "Giri", opponent: "Giri"}`
     - `{player: "Giri", opponent: "Gukesh"}`

4. **`where player != opponent`** filters out self-matches

The result: each pairing expands into both player/opponent perspectives.

### Finding Tie-Breaks

Now we can append the same count query to find players who faced each other
more than once:

```mdtest-command
super -s -c "
  split(pairing, ' ')
  | unnest {all_pairings:this, player:this} into (
      unnest {player: this.player, opponent: all_pairings} into (
        where player != opponent
        | cut player, opponent
      )
    )
  | count(this) by player, opponent
  | where count > 1
  | sort player, opponent
" pairings.sup
```

```mdtest-output
{player:"Gukesh",opponent:"Wei",count:2::uint64}
{player:"Wei",opponent:"Gukesh",count:2::uint64}
```

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v0.1.0
```
