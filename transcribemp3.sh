#!/bin/bash
set -euo pipefail

# Check for available Whisper CLI (whisper or whisper-cli)
if ! command -v whisper >/dev/null 2>&1 && ! command -v whisper-cli >/dev/null 2>&1; then
  echo "Whisper CLI is not installed. Install with: pip install openai-whisper" >&2
  exit 1
fi

# Folder to scan (current folder by default)
INPUT_DIR="${1:-.}"

if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: input directory does not exist: $INPUT_DIR" >&2
  exit 1
fi

shopt -s nullglob
files=( "$INPUT_DIR"/*.mp3 )
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "No mp3 files found in $INPUT_DIR. Nothing to transcribe."
  exit 0
fi

# Prefer `whisper` if available, otherwise use `whisper-cli`.
if command -v whisper >/dev/null 2>&1; then
  WHISPER_CMD=whisper
else
  WHISPER_CMD=whisper-cli
fi

for file in "${files[@]}"; do
  base="${file%.mp3}"

  echo "Transcribing: $file"

  "$WHISPER_CMD" \
    -f "$file" \
    -l ro \
    -m ~/models/whisper/ggml-large-v3.bin \
    -otxt \
    -of "$(basename "$file" .mp3)" \
    --beam-size 5 \
    --best-of 5 \
    --temperature 0.0 \
    --temperature-inc 0.2 \
    --max-context 0

  echo "Saved transcript to: ${base}.txt"
done
