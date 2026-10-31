---
title: "Cloudflare Log Durations"
name: cloudflare-durations
description: "Parsing Cloudflare edge timestamps, computing request durations, and bucketing for analysis."
layout: default
nav_order: 12
parent: Tutorials
superdb_version: "0.4.0"
last_updated: "2026-10-31"
---

# Cloudflare Log Durations

*Narrative tutorial — examples reference external Cloudflare log data.*

Many Cloudflare log entries include edge timestamps like `@EdgeStartTimestamp`
and `@EdgeEndTimestamp`. Computing request durations from these is a common
analysis task — and a good example of SuperDB's string cleaning, time parsing,
and bucketing capabilities.

## The Problem

Cloudflare timestamps often arrive with extra escaping:

```
"@EdgeStartTimestamp":"\"2025-04-22T18:16:46Z\""
```

We need to strip the escaped quotes, parse as time values, compute durations,
and then analyze the distribution.

## Step 1: Clean and Compute Durations

```bash
super -s -c "
  drop Message, Service, Env
  | start := regexp_replace(this['@EdgeStartTimestamp'], '[^A-Z0-9-:]', ''),
    end := regexp_replace(this['@EdgeEndTimestamp'], '[^A-Z0-9-:]', '')
  | start := start::timestamp, end := end::timestamp
  | dur := (end - start)::duration
  | cut start, end, dur
" cloudflare-extract.csv > cf-durations.sup
```

Key techniques:
- `regexp_replace` strips everything except alphanumerics, hyphens, and colons
- `::timestamp` casts the cleaned strings to timestamp values (this type was
  named `time` before v0.4.0)
- Duration is `end - start`, cast to `duration`. In v0.4.0, subtracting two
  timestamps returns a `timestamp` (e.g. `1970-01-01T00:00:04Z`) instead of a
  `duration` (`4s`), so the explicit `::duration` cast is needed for `bucket()`
  to produce duration buckets

## Step 2: Bucket and Analyze

```bash
super -s -c "
  log_count := collect(this) by bucket(dur, 3s)
  | log_count := len(log_count)
  | sort bucket
" cf-durations.sup
```

This groups requests into 3-second duration buckets and counts how many fall
into each, giving a histogram of request latencies.

## Variations

Adjust the bucket size for different granularity:

```bash
-- Fine-grained: 500ms buckets
super -s -c "count() by bucket(dur, 500ms) | sort bucket" cf-durations.sup

-- Coarse: 30s buckets
super -s -c "count() by bucket(dur, 30s) | sort bucket" cf-durations.sup
```
