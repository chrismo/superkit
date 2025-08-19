#!/usr/bin/env bash

set -euo pipefail

echo '================================'
echo '================================'
echo '================================'
export ASDF_SUPERDB_VERSION=ref:687d649 # Aug 15th 2025

super --version

time super -s -c "
  func root(): ( time('2025-08-17') )

  fork
    (
      -- daily
      --   the fork outputs are effectively like a UNION sql clause
      fork
      (where win is not null and ts > root() - 1d | count() by win, game_type)
      (where win is not null and ts > root() - 1d | count() by win)
      | sort game_type asc | put period:='today'
    )
    (
      -- total
      fork
      (where win is not null | count() by win, game_type)
      (where win is not null | count() by win)
      | sort game_type asc | put period:='total'
    )
  --| rename _:=game_type
  | fuse
  | cut period,game_type,win,count
  | order by period,game_type
" ./moar_subqueries.sup

echo '........'

# super -j -c "shapes" ./moarr_subquerses.sup
echo '-'

# This takes more user time, because threads maybe?
time super -s -c "
  func root(): ( time('2025-08-17') )

  select game_type, win, count(*) as today
  from './moar_subqueries.sup'
  where ts > (root() - 1d)
  group by game_type, win

  UNION ALL

  select game_type, win, count(*) as week
  from './moar_subqueries.sup'
  where ts > (root() - 1w)
  group by game_type, win

  UNION ALL

  select game_type, win, count(*) as total
  from './moar_subqueries.sup'
  where ts is not null
  group by game_type, win
"
echo '.-.-.-.'

time super -s -c "
  select
    (select count(*)
     from './moar_subqueries.sup'
     where win is not null) as total_games,
    (select count(*)
     from './moar_subqueries.sup'
     where win=true) as total_wins,
    (select count(*)
     from './moar_subqueries.sup'
     where ts > now() - 1d) as today_games,
    (select count(*)
     from './moar_subqueries.sup'
     where ts > now() - 1d
       and win=true) as today_wins
"

# SELECT
#     (SELECT COUNT(*) FROM orders) AS total_orders,
#     (SELECT COUNT(*) FROM orders WHERE order_date >= NOW() - INTERVAL '30 days') AS recent_orders,
#     (SELECT COUNT(*) FROM orders WHERE order_value > 100) AS high_value_orders;

time super -S -c "
  func root(): ( time('2025-08-17') )

  SELECT
    COUNT(CASE WHEN game_type = 'r' THEN 1 ELSE NULL END) AS r_wins_total,
    COUNT(CASE WHEN game_type = 'c' THEN 1 ELSE NULL END) AS c_wins_total,
    COUNT(CASE WHEN game_type = 'b' THEN 1 ELSE NULL END) AS b_wins_total,
    COUNT() AS total_total
  FROM
    './moar_subqueries.sup'
  where win = true

  UNION ALL

  SELECT
    COUNT(CASE WHEN game_type = 'r' THEN 1 ELSE NULL END) AS r_wins_total,
    COUNT(CASE WHEN game_type = 'c' THEN 1 ELSE NULL END) AS c_wins_total,
    COUNT(CASE WHEN game_type = 'b' THEN 1 ELSE NULL END) AS b_wins_total,
    COUNT() AS total_total
  FROM
    './moar_subqueries.sup'
  where win = true
    and ts > root() - 1d
"

time super -S -c "
  func root(): ( time('2025-08-17') )

  SELECT
    COUNT(CASE WHEN game_type = 'r' THEN 1 ELSE NULL END) AS r_wins_total,
    COUNT(CASE WHEN game_type = 'c' THEN 1 ELSE NULL END) AS c_wins_total,
    COUNT(CASE WHEN game_type = 'b' THEN 1 ELSE NULL END) AS b_wins_total,
    COUNT() AS total_total
  from './moar_subqueries.sup'
  where win = true

  UNION ALL

  SELECT
    COUNT(CASE WHEN game_type = 'r' THEN 1 ELSE NULL END) AS r_wins_total,
    COUNT(CASE WHEN game_type = 'c' THEN 1 ELSE NULL END) AS c_wins_total,
    COUNT(CASE WHEN game_type = 'b' THEN 1 ELSE NULL END) AS b_wins_total,
    COUNT() AS total_total
  from './moar_subqueries.sup'
  where win = true
    and ts > root() - 1d
"
