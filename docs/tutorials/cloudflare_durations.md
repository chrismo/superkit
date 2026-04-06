---
title: "Cloudflare Log Durations"
name: cloudflare-durations
description: "Parsing Cloudflare edge timestamps, computing request durations, and bucketing for analysis."
layout: default
nav_order: 12
parent: Tutorials
superdb_version: "0.3.0"
last_updated: "2026-04-05"
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
  | start := start::time, end := end::time
  | dur := end - start
  | cut start, end, dur
" cloudflare-extract.csv > cf-durations.sup
```

Key techniques:
- `regexp_replace` strips everything except alphanumerics, hyphens, and colons
- `::time` casts the cleaned strings to time values
- Duration is simply `end - start` — SuperDB handles time arithmetic natively

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
