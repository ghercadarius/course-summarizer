#!/bin/bash
set -euo pipefail

# Usage: convertmp3.sh [target_dir]
# Converts all .mp4 files in the target directory to .mp3.
# Defaults to current directory when no argument is provided.
TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: target directory does not exist: $TARGET_DIR" >&2
    exit 1
fi

shopt -s nullglob
files=( "$TARGET_DIR"/*.mp4 )
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No mp4 files found in $TARGET_DIR. Nothing to convert."
    exit 0
fi

for f in "${files[@]}"; do
    base="${f%.mp4}"
    ffmpeg -i "$f" -vn -acodec libmp3lame -q:a 2 "${base}.mp3"
done
