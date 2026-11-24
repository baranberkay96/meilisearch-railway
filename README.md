# Deploy and Host Meilisearch with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/meilisearch-158-search-engine?referralCode=20H68q)

Meilisearch is an open-source search engine with a simple REST API: typo-tolerant full-text search, filters, facets, geo search and vector or hybrid (AI) search, with answers in milliseconds. This template runs the official Meilisearch Community Edition on a Railway volume, secured with a generated master key.

## About Hosting Meilisearch

Meilisearch stores its indexes in an on-disk LMDB database, so hosting it needs a persistent volume, a master key that protects every route in production mode, and enough RAM for indexing. This community template builds the official `getmeili/meilisearch` image (pinned by digest) with a small start script, mounts a Railway volume at `/meili_data`, generates a 40-character master key and listens dual-stack so other Railway services reach it on the private network while browsers use the public HTTPS domain. Bad values in the deploy form never crash the service: they fall back to safe defaults, and a missing or short master key locks the API instead of opening it.

## Common Use Cases

- Instant search for websites, docs and e-commerce catalogs (InstantSearch, React/Vue SDKs)
- Search backend for apps such as LibreChat, Strapi, Directus or your own API
- Semantic and hybrid search with OpenAI, Hugging Face, Ollama or REST embedders
- A self-hosted, cost-predictable alternative to Algolia

## Dependencies for Meilisearch Hosting

- One service built from the official Meilisearch Community Edition image
- A Railway volume at `/meili_data` (database, dumps, snapshots)

### Deployment Dependencies

- [Meilisearch documentation](https://www.meilisearch.com/docs)
- [Configuration options](https://www.meilisearch.com/docs/learn/self_hosted/configure_meilisearch_at_launch)
- [Security and API keys](https://www.meilisearch.com/docs/learn/security/basic_security)
- [Meilisearch releases](https://github.com/meilisearch/meilisearch/releases)

### Implementation Details

| Service | What runs inside | Volume | Port |
|---|---|---|---|
| Meilisearch | Meilisearch 1.58.0 Community Edition | `/meili_data` | 7700, public domain |

**First steps**

1. Copy `MEILI_MASTER_KEY` from the service's Variables tab.
2. Check `https://{your-domain}/health` returns `{"status":"available"}`.
3. List the generated keys: `curl -H "Authorization: Bearer {master-key}" https://{your-domain}/keys`. Meilisearch creates a **Default Search API Key** (safe for browsers) and a **Default Admin API Key** (for your backend).
4. Add documents: `curl -X POST https://{your-domain}/indexes/movies/documents -H "Authorization: Bearer {admin-key}" -H "Content-Type: application/json" --data-binary @movies.json`, then search with `POST /indexes/movies/search`.

Never put the master key in frontend code; create keys with only the actions and indexes each client needs.

**Web dashboard (optional)**

Meilisearch serves its small built-in dashboard only in `development` mode. In this template the master key rule (16+ characters) is enforced in both modes, so with `MEILI_ENV=development` every API call, including the dashboard's, still needs a key: open `https://{your-domain}/` and paste an admin or search key. Switch back to `production` when you no longer need it.

**Connecting other Railway services**

Reference `${{Meilisearch.MEILISEARCH_PRIVATE_URL}}` (for example `http://meilisearch.railway.internal:7700`) and an API key from a backend service. Private traffic does not count as egress.

**Variables**

| Variable | Default | Purpose |
|---|---|---|
| `MEILI_MASTER_KEY` | generated, 40 chars | Protects every route; at least 16 characters |
| `MEILI_ENV` | `production` | `development` also serves Meilisearch's built-in web dashboard at `/` (see below) |
| `MEILI_NO_ANALYTICS` | `true` | Telemetry off |
| `MEILI_UPGRADE_DB` | `true` | Dumpless upgrade when you raise the version |
| `MEILI_SCHEDULE_SNAPSHOT` | empty (off) | Seconds between snapshots in `/meili_data/snapshots` |
| `MEILI_HTTP_PAYLOAD_SIZE_LIMIT` | `100MB` | Largest request body |
| `MEILI_LOG_LEVEL` | `INFO` | Log verbosity |

Any other [Meilisearch option](https://www.meilisearch.com/docs/learn/self_hosted/configure_meilisearch_at_launch) can be added as a `MEILI_*` variable. A master key shorter than 16 characters is replaced by a random one (API locked, explained in the log) until you set a proper key; other invalid values fall back to the default.

**Backups**

Create a dump with `POST /dumps` (stored in `/meili_data/dumps`) or turn on scheduled snapshots. Both count toward the volume size. To restore, set `MEILI_IMPORT_DUMP` or `MEILI_IMPORT_SNAPSHOT` to the file path for one start.

**Scaling and upgrades**

Meilisearch is a single node here: scale it vertically. Indexing is the heavy part; Meilisearch sizes its indexing memory from the container limit (two thirds of it) and uses half of the available cores. Plan RAM for your index size: small indexes run in 100-300 MB, millions of documents need several GB. To upgrade, change the tag and digest in `services/meilisearch/Dockerfile` (Eject the repo first), create a dump, and redeploy; `MEILI_UPGRADE_DB=true` upgrades the database in place.

**Resources**

Measured on Railway: about 100 MB RAM idle with a small index, near 0 vCPU; the volume costs $0.15/GB-month. Trial is enough for small indexes.

**Licence**

This template uses the Community Edition (MIT). Enterprise Edition features such as sharding are not included.

### Why Deploy Meilisearch on Railway?

Meilisearch needs a persistent disk, HTTPS and a private network to your app, which Railway gives a single service without setup. You get a secured search API in about a minute, and pay only for the RAM and disk your indexes use. This is a community template, not affiliated with Meilisearch.
