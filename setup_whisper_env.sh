#!/bin/bash
set -euo pipefail

ENV_DIR="whisper-env"
PYTHON_BIN=""

# Pick an available Python 3 interpreter.
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    echo "Error: Python is not installed." >&2
    exit 1
fi

if [ ! -d "$ENV_DIR" ]; then
    echo "Creating virtual environment: $ENV_DIR"
    "$PYTHON_BIN" -m venv "$ENV_DIR"

    # shellcheck disable=SC1091
    source "$ENV_DIR/bin/activate"

    echo "Upgrading pip..."
    pip install --upgrade pip

    echo "Installing Whisper package (openai-whisper)..."
    pip install openai-whisper

    echo "Done. Environment created at: $ENV_DIR"
else
    echo "Environment already exists: $ENV_DIR"
fi

echo "To activate it, run: source $ENV_DIR/bin/activate"
