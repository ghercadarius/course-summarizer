#!/bin/bash
set -euo pipefail

INPUT_DIR="${1:-./input}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERT_SCRIPT="$SCRIPT_DIR/convertmp3.sh"
TRANSCRIBE_SCRIPT="$SCRIPT_DIR/transcribemp3.sh"

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: input folder does not exist: $INPUT_DIR" >&2
    exit 1
fi

if [ ! -f "$CONVERT_SCRIPT" ]; then
    echo "Error: missing script: $CONVERT_SCRIPT" >&2
    exit 1
fi

if [ ! -f "$TRANSCRIBE_SCRIPT" ]; then
    echo "Error: missing script: $TRANSCRIBE_SCRIPT" >&2
    exit 1
fi

# Check for whisper-cli at system level
if ! command -v whisper-cli >/dev/null 2>&1; then
    echo "Error: whisper-cli is not installed at system level." >&2
    exit 1
fi

# Keep track of MP3 files that did not exist before conversion so we can clean them up.
declare -a TEMP_MP3S=()
PIPELINE_SUCCESS=0
shopt -s nullglob
for mp4 in "$INPUT_DIR"/*.mp4; do
    mp3="${mp4%.mp4}.mp3"
    if [ ! -f "$mp3" ]; then
        TEMP_MP3S+=("$mp3")
    fi
done
shopt -u nullglob

cleanup_temp_mp3s() {
    if [ "$PIPELINE_SUCCESS" -ne 1 ]; then
        echo "Pipeline did not complete successfully. Keeping temporary MP3 files for retry/debug."
        return
    fi

    if [ "${#TEMP_MP3S[@]}" -eq 0 ]; then
        return
    fi

    for mp3 in "${TEMP_MP3S[@]}"; do
        if [ -f "$mp3" ]; then
            rm -f -- "$mp3"
            echo "Deleted temporary MP3: $mp3"
        fi
    done
}

# Always attempt cleanup at script end, including failure paths.
trap cleanup_temp_mp3s EXIT

echo "Converting MP4 files to MP3 in: $INPUT_DIR"
bash "$CONVERT_SCRIPT" "$INPUT_DIR"

echo "Transcribing MP3 files from: $INPUT_DIR"
bash "$TRANSCRIBE_SCRIPT" "$INPUT_DIR"

PIPELINE_SUCCESS=1
echo "Pipeline complete."
