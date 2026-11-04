#!/bin/bash
# Genera un par de claves WireGuard por router (ubu-fw, rt-hue, rt-ter) en claves/.
# Las claves privadas NO se suben a Git (.gitignore): cada uno genera las suyas.
set -e
cd "$(dirname "$0")"
mkdir -p claves
docker run --rm -v "$PWD/claves:/c" gn-red:1.0 bash -c '
  umask 077
  for r in ubu-fw rt-hue rt-ter; do
    [ -f /c/$r.key ] || { wg genkey > /c/$r.key; wg pubkey < /c/$r.key > /c/$r.pub; }
  done'
ls -l claves
