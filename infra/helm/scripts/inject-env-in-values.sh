#!/usr/bin/env bash
# Usage: ./inject-env-in-values.sh path/to/.env
# Generate charts/shwet/values-secret.yaml (only secret section)
set -euo pipefail

ENV_FILE=${1:-.env}
OUTPUT_FILE="infra/helm/charts/shwet/values-secret.yaml"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE does not exist."
  exit 1
fi

secret_lines=()

while IFS= read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  case "$line" in \#*) continue ;; esac

  key="${line%%=*}"
  value="${line#*=}"

  value="${value%\"}"; value="${value#\"}"
  value="${value%\'}"; value="${value#\'}"

  secret_lines+=("  $key: \"$value\"")
done < "$ENV_FILE"

{
  echo "secret:"
  for l in "${secret_lines[@]}"; do echo "$l"; done
} > "$OUTPUT_FILE"

echo "✅ Generated $OUTPUT_FILE"