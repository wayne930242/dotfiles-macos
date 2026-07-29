#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_DIR/.aerospace.toml"

expected_startup_layout="after-startup-command = ['layout --workspace Q --root h_tiles']"

if ! grep -Fqx "$expected_startup_layout" "$CONFIG_FILE"; then
    echo "FAIL: Q workspace is not forced to h_tiles after AeroSpace startup" >&2
    exit 1
fi

echo "PASS: AeroSpace startup layout contract"
