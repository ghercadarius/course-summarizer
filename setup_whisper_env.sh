#!/bin/bash
set -euo pipefail

# Verify that whisper-cli is available at system level.
if ! command -v whisper-cli >/dev/null 2>&1; then
    echo "Error: whisper-cli is not installed at system level." >&2
    echo "Please install whisper-cli using your system's package manager or pip." >&2
    exit 1
fi

echo "whisper-cli is available:"
whisper-cli --version
