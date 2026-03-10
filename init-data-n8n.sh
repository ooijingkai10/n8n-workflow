#!/bin/bash
set -e

cat <<-EOT >credentials.json
[
  {
    "updatedAt": "2026-03-06T05:52:19.649Z",
    "createdAt": "2026-03-06T05:52:19.653Z",
    "id": "tJk4TZtu62G05Qy6",
    "name": "Postgres account",
    "data": {
      "host": "postgres",
      "database": "n8n",
      "user": "changeUser",
      "password": "changePassword"
    },
    "type": "postgres",
    "isManaged": false,
    "isGlobal": false,
    "isResolvable": false,
    "resolvableAllowFallback": false,
    "resolverId": null
  },
  {
    "updatedAt": "2026-03-06T05:53:39.516Z",
    "createdAt": "2026-03-06T05:53:39.521Z",
    "id": "jaUzCS8DoF2kg4L2",
    "name": "IMAP account",
    "data": {
      "user": "${IMAP_USER}",
      "password": "${IMAP_PASSWORD}",
      "host": "${IMAP_HOST}"
    },
    "type": "imap",
    "isManaged": false,
    "isGlobal": false,
    "isResolvable": false,
    "resolvableAllowFallback": false,
    "resolverId": null
  },
  {
    "updatedAt": "2026-03-07T04:18:08.643Z",
    "createdAt": "2026-03-06T05:55:32.015Z",
    "id": "nbHkKJJySQ1pgycv",
    "name": "Telegram account",
    "data": {
      "accessToken": "${TELEGRAM_BOT_TOKEN}"
    },
    "type": "telegramApi",
    "isManaged": false,
    "isGlobal": false,
    "isResolvable": false,
    "resolvableAllowFallback": false,
    "resolverId": null
  }
]
EOT

n8n import:credentials --input credentials.json
n8n import:workflow --input=/workflows/spendtracker-workflow.json
n8n import:workflow --input=/workflows/telegramquery.json
n8n publish:workflow --id=spendtracker
n8n publish:workflow --id=telegramquery
