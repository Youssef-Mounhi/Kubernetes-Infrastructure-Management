#!/usr/bin/env bash
# Usage: ./inject-env-in-values.sh path/to/.env
# Generates values-secret.yaml with config and secret sections
# Automatically strips surrounding quotes from .env values

ENV_FILE=${1:-.env}     
OUTPUT_FILE=infra/helm/values-secret.yaml

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE does not exist."
  exit 1
fi

# Initialize arrays
config_lines=()
secret_lines=()
current_section="config"

while IFS= read -r line || [ -n "$line" ]; do
  # skip empty lines
  [ -z "$line" ] && continue

  # switch section
  if [ "$line" = "# SECRETS" ]; then
    current_section="secret"
    continue
  fi

  # skip other comments
  case "$line" in
    \#*) continue ;;
  esac

  # split key and value
  key="${line%%=*}"
  value="${line#*=}"

  # strip surrounding quotes if present
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"

  # append to proper array
  if [ "$current_section" = "config" ]; then
    config_lines+=("  $key: \"$value\"")
  else
    secret_lines+=("  $key: \"$value\"")
  fi
done < "$ENV_FILE"

# Write to output file
{
  echo "config:"
  for l in "${config_lines[@]}"; do echo "$l"; done

  if [ ${#secret_lines[@]} -gt 0 ]; then
    echo "secret:"
    for l in "${secret_lines[@]}"; do echo "$l"; done
  fi
} > "$OUTPUT_FILE"

echo "✅ Generated $OUTPUT_FILE"