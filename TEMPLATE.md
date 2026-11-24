# TEMPLATE: Meilisearch 1.58 Search Engine

Composer spec. `template.json` is the machine-readable copy.

## Service

| Field | Value |
|---|---|
| Name | Meilisearch |
| Source | repo `baranberkay96/meilisearch-railway`, root `/services/meilisearch` |
| Base | `getmeili/meilisearch:v1.58.0@sha256:cee0d2e3…` (Community Edition, released 2026-11-23, checked 2026-11-24) |
| Public domain | yes, target port 7700 |
| Healthcheck | `/health`, 300 s |
| Restart | ALWAYS |
| Volume | `/meili_data` |

Variables: `MEILI_MASTER_KEY` (secret 40, alphanumeric), `MEILI_ENV` (production), `MEILI_NO_ANALYTICS` (true), `MEILI_UPGRADE_DB` (true), `MEILI_SCHEDULE_SNAPSHOT` (empty = off), `MEILI_HTTP_PAYLOAD_SIZE_LIMIT` (100MB), `MEILI_LOG_LEVEL` (INFO), `PORT` (7700), `MEILISEARCH_PRIVATE_URL`, `MEILISEARCH_PUBLIC_URL`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` (15). No required inputs.

## Design

- `railway-meilisearch` (sh) validates every value and falls back with a log warning (STANDARD 8.29). Master key shorter than 16 bytes (or empty) → a random 40-char key nobody knows (API locked, fix explained in the log) instead of an exit (production) or an open instance (development).
- `MEILI_HTTP_ADDR=[::]:$PORT` (dual-stack, actix). DB, dumps and snapshots under `/meili_data`.
- Indexing memory: Meilisearch reads the cgroup limit itself (`total_memory_bytes()` uses `cgroup_limits()`), threads via `available_parallelism()` (cgroup-aware), so no override is needed (STANDARD 8.15 checked).
- `MEILI_UPGRADE_DB=true`: raising the pinned version upgrades the database in place instead of failing on a version mismatch.
- Built-in dashboard only in `MEILI_ENV=development`; the key rule is enforced there too, so it stays behind the API key.

## Improvements over market templates

- Market templates use `latest` (vipulasri) or v1.9.0 (2024) and crash-loop on a short key. This one pins 1.58.0 by digest, binds dual-stack, enforces the key in both modes without failing the deploy, turns telemetry off, enables dumpless upgrades and documents keys, backups and private-network use.

## Resources

| Service | Idle RAM | Typical RAM | CPU |
|---|---|---|---|
| Meilisearch | IDLE_RAM (measured) | 100 MB-2 GB+ (index size, indexing bursts) | ≈0 idle, bursts while indexing |

Estimated cost: $1-5/month for small indexes + volume ($0.15/GB-month). Minimum plan: Trial (small indexes).

## Verification checklist

- `/health` 200 without a key; `/keys` 401 without, 200 with the master key.
- Create an index, add documents, search with the Default Search API Key; data survives a redeploy.
- `MEILI_MASTER_KEY=short` → deploy SUCCESS, API locked, warning in the log.
- `MEILI_ENV=development` → dashboard at `/`, API still needs a key.

## Open questions

- Meilisearch releases weekly; the listing name carries the pinned minor (1.58).
