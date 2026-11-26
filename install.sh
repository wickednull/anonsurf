#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [[ ! -f SHA256SUMS ]]; then
  echo "error: SHA256SUMS is missing" >&2
  exit 1
fi

echo "==> Verifying release files"
sha256sum -c SHA256SUMS

if [[ $(id -u) -eq 0 ]]; then
  sudo_cmd=()
else
  sudo_cmd=(sudo)
fi

echo "==> Installing dependencies and AnonSurf packages"
"${sudo_cmd[@]}" apt-get update
"${sudo_cmd[@]}" apt-get install -y ./dist/*.deb

echo
echo "AnonSurf installed. Try:"
echo "  anonsurf status --json"
echo "  sudo anonsurf start"
