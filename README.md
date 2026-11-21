[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/pydio-cells-1?utm_medium=integration&utm_source=button&utm_campaign=pydio-cells)

# Pydio Cells on Railway

One-click [Pydio Cells](https://github.com/pydio/cells) (open-source file sharing and document collaboration, AGPL-3.0) for Railway.

## What it deploys

| Service | What it does |
|---|---|
| **Pydio Cells** | The web app, WebDAV and S3 gateway, built from this repo's `Dockerfile` (official `pydio/cells:5.1.1`, pinned by digest). Files, the search index and Cells' own config live on a volume at `/var/cells`. Public, with a Railway domain and a health check on `/a/frontend/bootconf`. |
| **Postgres** | Railway's PostgreSQL. Holds users, roles, ACLs, workspaces and the file index. Private network only. |

Version: **Pydio Cells 5.1.1** (`pydio/cells:5.1.1@sha256:91a82e3357a7c76722ff094c2ba2236eccf7819cb6ff9bf4e8aae66627174537`).

## First boot

`railway-start.sh` runs Cells' headless install on the first boot (no config on the volume yet): it creates the database schema, the default datasources and the admin account, then starts Cells. There is no setup wizard, so nobody can claim the instance before you.

Sign in with the user `admin` and the password in the **Pydio Cells** service's `CELLS_ADMIN_PASSWORD` variable (generated at deploy). Change it afterwards in *My Account*: the variable is only read on the very first boot.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `CELLS_ADMIN_LOGIN` | `admin` | First admin's user name, first boot only |
| `CELLS_ADMIN_PASSWORD` | `${{secret(24,…)}}` | Generated first admin password, first boot only |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | `${{Postgres.PG…}}` | References to the Postgres service |
| `PORT` | `8080` | Port Cells listens on |

Optional, set them yourself if you need them: `CELLS_SITE_EXTERNAL` (public URL if you add a custom domain; by default `https://$RAILWAY_PUBLIC_DOMAIN`), `CELLS_APPLICATION_TITLE`. Mail (SMTP) is set in the Cells Console after deploy.

## Resources

Cells is a Go binary with many internal services. It idles at about 250–300 MB RAM, so it fits Railway's 0.5 GB per-service limit for a small team. The start script sets `GOMEMLIMIT` to 85 % of the container's memory limit so the Go runtime collects garbage before the limit is reached. Give it 1 GB or more for many users or large uploads.

## Updates

This template builds from this repository. When the pinned Cells version is bumped on `main`, Railway shows an "update available" notice on your project, and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first. Back up the volume and the database before you apply a major version.

## Files

- `Dockerfile`: the pinned official image plus the start script.
- `railway-start.sh`: plain HTTP on `$PORT` (Railway terminates TLS), headless first-boot install, then `cells start`. Any failure exits non-zero, so Railway's restart policy applies.
