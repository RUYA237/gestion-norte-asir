#!/bin/bash
set -euo pipefail
export RESTIC_REPOSITORY=rest:http://192.168.116.143:8000/ubu-svc/
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/pass-bkp01"
export RESTIC_REST_USERNAME=ubu-svc
export RESTIC_REST_PASSWORD="$(cat "$HOME/.config/restic/rest-pass")"
TMP="$HOME/backup-tmp"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT
for i in $(seq 1 30); do
  podman exec postgres pg_isready -U admin -d gestion_norte -q && break
  sleep 2
done
podman exec postgres pg_dump -U admin -Fc gestion_norte > "$TMP/gestion_norte.dump"
podman exec postgres pg_dumpall -U admin --globals-only > "$TMP/roles.sql"
test -s "$TMP/gestion_norte.dump"
cat "$TMP/gestion_norte.dump" | restic backup --stdin --stdin-filename gestion_norte.dump --tag bd
test -s "$TMP/roles.sql"
cat "$TMP/roles.sql" | restic backup --stdin --stdin-filename roles.sql --tag roles
