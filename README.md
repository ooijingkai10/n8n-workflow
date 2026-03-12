# n8n Spend Tracker Setup & Upgrade Guide

This repo runs n8n + PostgreSQL via Docker Compose, imports workflows automatically, and supports local MCC lookup from `mcc/mcclist.csv`.

## Prerequisites

- Docker + Docker Compose installed.
- A `.env` file with all required variables.

Required env vars:

| Variable | Description |
|---|---|
| `POSTGRES_USER` | PostgreSQL root username |
| `POSTGRES_PASSWORD` | PostgreSQL root password |
| `POSTGRES_DB` | PostgreSQL database name |
| `POSTGRES_NON_ROOT_USER` | PostgreSQL non-root username used by n8n |
| `POSTGRES_NON_ROOT_PASSWORD` | PostgreSQL non-root password used by n8n |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token |
| `TELEGRAM_GROUP_ID` | Telegram group/chat ID |
| `IMAP_USER` | IMAP username (for Gmail, full email) |
| `IMAP_PASSWORD` | IMAP password (for Gmail, app password) |
| `IMAP_HOST` | IMAP server host |

---

## New Users (Fresh Setup)

1. Clone and enter repo:

```sh
git clone https://github.com/ooijingkai10/n8n-workflow.git
cd n8n-workflow
```

2. Create `.env`:

```sh
cp .env.example .env
```

3. Start services:

```sh
docker compose up -d
```

This starts PostgreSQL + n8n, creates base tables, imports workflows, and loads MCC reference data from CSV during first DB initialization.

4. Open n8n (optional):

- <http://localhost:5678>

---

## Existing Users (Upgrade + DB Migration)

Use this when you already have an older database volume and are pulling the latest repo changes.

### 1) Backup your current database (recommended)

```sh
docker compose exec postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > backup-before-migration.sql
```

### 2) Pull latest code and restart services

```sh
git pull
docker compose up -d
```

### 3) Run migration script once

```sh
docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /dev/stdin < migration.sql
```

This migration handles:

- `transactions.merchant_id` backfill + FK
- `mcc_reference` table creation (Note: Ensure that the mcclist.csv is loaded onto postgres container in the /mcc path)
- index creation and extension setup

### 3) Restart n8n

```sh
docker compose restart n8n
```

---

## Useful Commands

Start:

```sh
docker compose up -d
```

Stop:

```sh
docker compose down
```

View logs:

```sh
docker compose logs -f
```

---

## Security Notes

- Keep `.env` private and out of version control.
- Rotate Telegram and IMAP credentials if exposed.
