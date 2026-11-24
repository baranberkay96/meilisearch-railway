# NOTICE: Meilisearch template

This is a community template. It is not made, endorsed or supported by Meili SAS or Railway.

## Components

| Component | Source | License | How it is used |
|---|---|---|---|
| Meilisearch 1.58.0 Community Edition (`getmeili/meilisearch:v1.58.0@sha256:cee0d2e31191594ff8e1651eb144aabd95b389a0bc3532327ecfb9ed91dffe7e`) | https://github.com/meilisearch/meilisearch | MIT (Copyright (c) 2019-2025 Meili SAS) and OpenLDAP Public License (LMDB) | Official image, unmodified, as the base image |

The `getmeili/meilisearch` image is the Community Edition build (the publish workflow builds Enterprise Edition features only into `getmeili/meilisearch-enterprise`). Enterprise Edition features (sharding, S3-streaming snapshots and others, Business Source License 1.1) are not part of this template.

## Files written for this template

`services/meilisearch/Dockerfile`, `services/meilisearch/railway-meilisearch.sh` and the documentation were written for this template and are offered under the MIT License.

## Upstream files checked (tag v1.58.0)

- `Dockerfile` (alpine 3.22 runtime, `WORKDIR /meili_data`, `MEILI_HTTP_ADDR` default), `.github/workflows/publish-docker-images.yml` (community vs enterprise images), `LICENSE`, `README.md` (editions).
- `crates/meilisearch/src/option.rs` (environment variable names, cgroup-aware indexing memory, `MEILI_UPGRADE_DB`, snapshot schedule) and `src/main.rs` (master key minimum 16 bytes in production; dashboard only in development).

## Market templates

The Meilisearch templates on the Railway marketplace (`getmeili/meilisearch:v1.9.0` image template, `vipulasri/meilisearch-railway`) and our own LibreChat template were reviewed for features only. No files or text were copied from third-party templates.
