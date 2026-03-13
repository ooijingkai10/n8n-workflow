#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./k8s/load-mcc-reference.sh [csv_path]

Examples:
  ./k8s/load-mcc-reference.sh mcc/mcclist.csv
  NAMESPACE=finance PG_POD_SELECTOR='app=postgres' ./k8s/load-mcc-reference.sh /tmp/mcclist.csv

Optional env vars:
  NAMESPACE, PG_POD_NAME, PG_POD_SELECTOR, PG_CONTAINER, MIGRATION_URL
USAGE
}

NAMESPACE="${NAMESPACE:-default}"
CSV_PATH="${CSV_PATH:-mcc/mcclist.csv}"
MIGRATION_URL="${MIGRATION_URL:-https://raw.githubusercontent.com/ooijingkai10/n8n-workflow/refs/heads/main/migration.sql}"
PG_POD_NAME="${PG_POD_NAME:-}"
PG_POD_SELECTOR="${PG_POD_SELECTOR:-app=postgres}"
PG_CONTAINER="${PG_CONTAINER:-}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ge 1 ]]; then
  CSV_PATH="$1"
fi

if [[ ! -f "$CSV_PATH" ]]; then
  echo "CSV file not found: $CSV_PATH"
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required"
  exit 1
fi

if [[ -z "$PG_POD_NAME" ]]; then
  PG_POD_NAME="$(kubectl get pods -n "$NAMESPACE" -l "$PG_POD_SELECTOR" -o jsonpath='{.items[0].metadata.name}')"
fi

if [[ -z "$PG_POD_NAME" ]]; then
  echo "Could not resolve postgres pod. Set PG_POD_NAME explicitly or adjust PG_POD_SELECTOR."
  exit 1
fi

KUBECTL_EXEC=(kubectl exec -i -n "$NAMESPACE" "$PG_POD_NAME")
if [[ -n "$PG_CONTAINER" ]]; then
  KUBECTL_EXEC+=( -c "$PG_CONTAINER" )
fi
KUBECTL_EXEC+=( -- /bin/sh -lc )

echo "Using postgres pod: $PG_POD_NAME (namespace: $NAMESPACE)"

echo "Running remote migration script: $MIGRATION_URL"
curl -fsSL "$MGRATION_URL" | "${KUBECTL_EXEC[@]}" 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'

echo "Clearing mcc_reference rows before CSV import..."
"${KUBECTL_EXEC[@]}" 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "TRUNCATE TABLE mcc_reference;"'

echo "Streaming local CSV to postgres via kubectl exec..."
cat "$CSV_PATH" | "${KUBECTL_EXEC[@]}" 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy mcc_reference (mcc, edited_description, combined_description, usda_description, irs_description, irs_reportable) FROM STDIN WITH (FORMAT csv, HEADER true)"'

echo "Ensuring index exists..."
"${KUBECTL_EXEC[@]}" 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE INDEX IF NOT EXISTS idx_mcc_reference_mcc ON mcc_reference (mcc);"'

echo "Done. mcc_reference loaded from $CSV_PATH"
