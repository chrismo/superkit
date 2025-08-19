# Moar Subqueries

## Fork

One hassle to this approach is the limit of 2 forks. Nesting forks works, but
makes constructing this query a bit more difficult.

## Full Sub-Selects
   
As of 20250815 build, this is much, much slower. I'm guessing it's doing a full
reload of the data file each time.

```
select
(select count(*)
from './moar_subqueries.sup'
where win is not null) as total_games,
...
```

## All Other SQL-Syntax Subqueries

They all take about the same amount of wall-time, but CPU usage is much higher
due to re-reading the file each time.
