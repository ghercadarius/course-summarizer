#!/usr/bin/env bash
set -euo pipefail

# Summarize each file in the output directory using llama-cli
# Configurable via environment variables (see Usage below)

MODEL="${MODEL:-/home/darius/models/qwen-7b-q5_kgm.gguf}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"
SUMMARY_SUFFIX="${SUMMARY_SUFFIX:-.summary.txt}"
# Use PROMPT_TEMPLATE with a single literal "%s" placeholder for the file contents
PROMPT_TEMPLATE="${PROMPT_TEMPLATE:-Summarize the following trascript with the topics it describes and what was discussed in it in english:\n\n%s}"
# If you set PROMPT (full prompt string containing %s) it will override PROMPT_TEMPLATE
LLAMA_CLI="${LLAMA_CLI:-llama-cli}"
# Additional llama-cli args (defaults taken from your example)
LLAMA_ARGS="${LLAMA_ARGS:---gpu --n-gpu-layers 12 --ctx 2048 -t 8 --temp 0.2 --top_p 0.95 -n 512}"

# Detect whether the llama-cli binary supports the --gpu flag; if not, drop it.
help_output=$("$LLAMA_CLI" --help 2>&1 || true)
supports_gpu=false
if echo "$help_output" | grep -q -- '--gpu\b'; then
  supports_gpu=true
fi

# Build final args array, excluding --gpu if unsupported
FINAL_LLAMA_ARGS=()
if [ -n "${LLAMA_ARGS:-}" ]; then
  read -r -a _args <<< "$LLAMA_ARGS"
  for tok in "${_args[@]}"; do
    if [ "$tok" = "--gpu" ] && [ "$supports_gpu" = false ]; then
      echo "Note: $LLAMA_CLI does not support --gpu; removing from LLAMA_ARGS."
      continue
    fi
    FINAL_LLAMA_ARGS+=("$tok")
  done
fi

if ! command -v "$LLAMA_CLI" >/dev/null 2>&1; then
  echo "Error: $LLAMA_CLI not found in PATH." >&2
  exit 1
fi

if [ ! -f "$MODEL" ]; then
  echo "Warning: model file '$MODEL' not found. Ensure MODEL points to a valid model file." >&2
fi

if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: output directory '$OUTPUT_DIR' does not exist." >&2
  exit 1
fi

shopt -s nullglob
for file in "$OUTPUT_DIR"/*; do
  [ -f "$file" ] || continue
  echo "Summarizing: $file"

  # Escape double quotes like in your example command, then load into TEXT
  TEXT=$(sed -e 's/"/\\"/g' "$file")

  # If PROMPT env var provided, use it as the template; otherwise use PROMPT_TEMPLATE
  if [ -n "${PROMPT:-}" ]; then
    template="$PROMPT"
  else
    template="$PROMPT_TEMPLATE"
  fi

  # Replace literal %s in template with the file contents
  PROMPT=${template//%s/$TEXT}

  out_file="${file}${SUMMARY_SUFFIX}"

  # Run llama-cli with additional args and write summary to out_file
  if ! "$LLAMA_CLI" -m "$MODEL" $LLAMA_ARGS -p "$PROMPT" > "$out_file"; then
    echo "Failed to summarize $file" >&2
  else
    echo "Wrote summary -> $out_file"
  fi
done

echo "All done."

# Usage notes:
# - Override variables by exporting them before running, e.g.:
#   export MODEL=/home/darius/models/qwen-7b-q5_kgm.gguf
#   export LLAMA_CLI=./build/bin/llama-cli
#   export LLAMA_ARGS='--gpu --n-gpu-layers 12 --ctx 2048 -t 8 --temp 0.2 --top_p 0.95 -n 512'
#   export OUTPUT_DIR=output
#   export SUMMARY_SUFFIX=.summary.txt
#   export PROMPT_TEMPLATE='Rezumă în 5 puncte, în limba română:\n\n%s'
#   export PROMPT='Rezumă în 3 puncte, în limba română:\n\n%s'  # optional override of template
#   ./summarize_outputs.sh
