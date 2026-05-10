#!/bin/bash

# Exit if whisper is not installed
if ! command -v whisper >/dev/null 2>&1; then
    echo "Whisper is not installed. Install with: pip3 install openai-whisper"
    exit 1
fi

# Folder to scan (current folder by default)
INPUT_DIR="${1:-.}"

# Loop through all mp3 files
for file in "$INPUT_DIR"/*.mp3; do
    # Skip if no mp3 files exist
    [ -e "$file" ] || { echo "No mp3 files found."; exit 0; }

    # Remove extension to create output filename
    base="${file%.mp3}"

    echo "Transcribing: $file"

    whisper-cli \
  -f "$file" \
  -l ro \
  -m ~/models/whisper/ggml-large-v3.bin \
  -otxt \
  -of "$(basename "$file" .mp3)"\
  --beam-size 5 \
  --best-of 5 \
  --temperature 0.0 \
  --temperature-inc 0.2 \
  --max-context 0

    echo "Saved transcript to: ${base}.txt"
done
