#!/bin/bash
set -euo pipefail

# Convert all .mp4 files in the current directory to .mp3.
# Exits quietly if no .mp4 files are present.
shopt -s nullglob
files=( *.mp4 )
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No mp4 files found. Nothing to convert."
    exit 0
fi

for f in "${files[@]}"; do
    base="${f%.mp4}"
    ffmpeg -i "$f" -vn -acodec libmp3lame -q:a 2 "${base}.mp3"
done
