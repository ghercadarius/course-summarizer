#!/bin/bash
set -euo pipefail

# Check for whisper-cli at system level
if ! command -v whisper-cli >/dev/null 2>&1; then
  echo "Error: whisper-cli is not installed." >&2
  exit 1
fi

# Ensure whisper-cli can load its shared library (libwhisper.so.1).
# Some installs require LD_LIBRARY_PATH to include non-default library dirs.
WHISPER_BIN="$(command -v whisper-cli)"

ensure_whisper_runtime() {
  if "$WHISPER_BIN" --help >/dev/null 2>&1; then
    return 0
  fi

  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:/usr/local/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:$HOME/.local/lib"

  if "$WHISPER_BIN" --help >/dev/null 2>&1; then
    return 0
  fi

  echo "Error: whisper-cli was found but cannot start (likely missing libwhisper.so.1 at runtime)." >&2
  echo "Current whisper-cli path: $WHISPER_BIN" >&2
  echo "Try one of the following:" >&2
  echo "  1) Install/repair whisper.cpp runtime libraries" >&2
  echo "  2) Add the libwhisper directory to LD_LIBRARY_PATH" >&2
  echo "  3) If installed in /usr/local/lib, run: sudo ldconfig" >&2
  exit 1
}

ensure_whisper_runtime

# Folders
INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-./output}"

if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: input directory does not exist: $INPUT_DIR" >&2
  exit 1
fi

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
  echo "Created output directory: $OUTPUT_DIR"
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
  local filename
  filename="$(basename "$file" .mp3)"

  echo "Transcribing: $file"

  # whisper-cli (ggml) invocation
  # GPU is enabled by default; use -ng to disable if needed
  whisper-cli \
    -f "$file" \
    -l ro \
    -m ~/models/whisper/ggml-large-v3.bin \
    -otxt \
    -of "$OUTPUT_DIR/$filename" \
    --beam-size 5 \
    --best-of 5 \
    --temperature 0.0 \
    --temperature-inc 0.2 \
    --max-context 0

  echo "Saved transcript to: $OUTPUT_DIR/${filename}.txt"
}

for file in "${files[@]}"; do
  run_transcription "$file"
done
