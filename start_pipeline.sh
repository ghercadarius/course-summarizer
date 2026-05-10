#!/bin/bash
set -euo pipefail

INPUT_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERT_SCRIPT="$SCRIPT_DIR/convertmp3.sh"
TRANSCRIBE_SCRIPT="$SCRIPT_DIR/transcribemp3.sh"
ENV_DIR="$SCRIPT_DIR/whisper-env"
ENV_ACTIVATE="$ENV_DIR/bin/activate"

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

if [ ! -f "$ENV_ACTIVATE" ]; then
    echo "Error: missing virtual environment activation script: $ENV_ACTIVATE" >&2
    echo "Create it first (example): ./setup_whisper_env.sh" >&2
    exit 1
fi

# Keep track of MP3 files that did not exist before conversion so we can clean them up.
declare -a TEMP_MP3S=()
shopt -s nullglob
for mp4 in "$INPUT_DIR"/*.mp4; do
    mp3="${mp4%.mp4}.mp3"
    if [ ! -f "$mp3" ]; then
        TEMP_MP3S+=("$mp3")
    fi
done
shopt -u nullglob

cleanup_temp_mp3s() {
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
(
    cd "$INPUT_DIR"
    bash "$CONVERT_SCRIPT"
)

echo "Activating Whisper environment: $ENV_DIR"
# shellcheck disable=SC1091
source "$ENV_ACTIVATE"

if ! command -v whisper >/dev/null 2>&1 && ! command -v whisper-cli >/dev/null 2>&1; then
    echo "Error: Whisper CLI is not available in $ENV_DIR." >&2
    echo "Install package in the environment (example): pip install openai-whisper" >&2
    exit 1
fi

echo "Transcribing MP3 files from: $INPUT_DIR"
(
    cd "$INPUT_DIR"
    bash "$TRANSCRIBE_SCRIPT" "."
)

echo "Pipeline complete."
