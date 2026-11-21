# Changelog

## 5.1.1 (2026-11-21)

First release of the template.

- Pydio Cells 5.1.1, official image `pydio/cells:5.1.1@sha256:91a82e3357a7c76722ff094c2ba2236eccf7819cb6ff9bf4e8aae66627174537`.
- Railway Postgres as the database, files on a volume at `/var/cells`.
- Headless first-boot install with a generated admin password (no setup wizard).
- Plain HTTP on `$PORT` behind Railway's TLS edge, health check on `/a/frontend/bootconf`.
- `GOMEMLIMIT` set from the container's memory limit.
