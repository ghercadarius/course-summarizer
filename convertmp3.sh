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

success_count=0
failed_count=0

for f in "${files[@]}"; do
    base="${f%.mp4}"

    # Validate container quickly; skip clearly broken inputs.
    if ! ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f" >/dev/null 2>&1; then
        echo "Skipping invalid mp4: $f" >&2
        failed_count=$((failed_count + 1))
        continue
    fi

    if ffmpeg -y -i "$f" -vn -acodec libmp3lame -q:a 2 "${base}.mp3"; then
        success_count=$((success_count + 1))
    else
        echo "Failed to convert: $f" >&2
        failed_count=$((failed_count + 1))
        continue
    fi
done

echo "Conversion summary: $success_count succeeded, $failed_count failed."
