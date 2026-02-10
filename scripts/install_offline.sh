#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/vendor"
REQ_FILE="$ROOT_DIR/requirements.txt"

if [ ! -d "$VENDOR_DIR" ]; then
  echo "Vendor directory not found: $VENDOR_DIR" >&2
  exit 1
fi

if [ ! -f "$REQ_FILE" ]; then
  echo "Requirements file not found: $REQ_FILE" >&2
  exit 1
fi

python3 -m pip install --no-index --find-links "$VENDOR_DIR" -r "$REQ_FILE"
