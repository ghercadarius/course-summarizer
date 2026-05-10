#!/bin/bash
set -euo pipefail

# Check for whisper-cli at system level
if ! command -v whisper-cli >/dev/null 2>&1; then
  echo "Error: whisper-cli is not installed." >&2
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

run_transcription() {
  local file="$1"
  local base
  base="${file%.mp3}"

  echo "Transcribing: $file"

  # whisper-cli (ggml) invocation with GPU support
  # Pass -gpu flag to enable GPU acceleration if available
  whisper-cli \
    -f "$file" \
    -l ro \
    -m ~/models/whisper/ggml-large-v3.bin \
    -otxt \
    -of "$(basename "$file" .mp3)" \
    -gpu auto \
    --beam-size 5 \
    --best-of 5 \
    --temperature 0.0 \
    --temperature-inc 0.2 \
    --max-context 0

  echo "Saved transcript to: ${base}.txt"
}

for file in "${files[@]}"; do
  run_transcription "$file"
done
