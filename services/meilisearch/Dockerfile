# syntax=docker/dockerfile:1
#
# Meilisearch 1.58.0 (Community Edition, MIT) for Railway.
#
# Base: the official getmeili/meilisearch image, multi-arch index digest
# checked 2026-11-24. To upgrade, change tag and digest together, read the
# release notes, and keep MEILI_UPGRADE_DB=true (dumpless upgrade) or import
# a dump.
FROM getmeili/meilisearch:v1.58.0@sha256:cee0d2e31191594ff8e1651eb144aabd95b389a0bc3532327ecfb9ed91dffe7e

COPY --chmod=0755 railway-meilisearch.sh /usr/local/bin/railway-meilisearch

ENV PORT=7700
WORKDIR /meili_data
EXPOSE 7700

ENTRYPOINT ["/usr/local/bin/railway-meilisearch"]
