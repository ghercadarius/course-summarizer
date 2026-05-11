#!/usr/bin/env bash
set -euo pipefail

# Summarize each file in the output directory using llama-cli
# Configurable via environment variables (see Usage below)

HF_MODEL="${HF_MODEL:-Qwen/Qwen2.5-7B-Instruct-GGUF:Q4_K_M}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"
SUMMARY_SUFFIX="${SUMMARY_SUFFIX:-.summary.txt}"
# Use PROMPT_TEMPLATE with a single literal "%s" placeholder for the file contents
PROMPT_TEMPLATE="${PROMPT_TEMPLATE:-Summarize the following trascript with the topics it describes and what was discussed in it in english:\n\n%s}"
# If you set PROMPT (full prompt string containing %s) it will override PROMPT_TEMPLATE
LLAMA_CLI="${LLAMA_CLI:-llama-cli}"
# Additional llama-cli args (most flags may not be supported with -hf)
LLAMA_ARGS="${LLAMA_ARGS:-}"

if ! command -v "$LLAMA_CLI" >/dev/null 2>&1; then
  echo "Error: $LLAMA_CLI not found in PATH." >&2
  exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: output directory '$OUTPUT_DIR' does not exist." >&2
  exit 1
fi

shopt -s nullglob
for file in "$OUTPUT_DIR"/*; do
  [ -f "$file" ] || continue
  echo "Summarizing: $file"

  # Escape double quotes and load file contents
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

  if ! timeout 300 "$LLAMA_CLI" -hf "$HF_MODEL" $LLAMA_ARGS -p "$PROMPT" < /dev/null > "$out_file" 2>&1; then
    echo "Failed to summarize $file" >&2
  else
    echo "Wrote summary -> $out_file"
  fi
done

echo "All done."

# Usage notes:
# - Override variables by exporting them before running, e.g.:
#   export HF_MODEL=Qwen/Qwen2.5-7B-Instruct-GGUF:Q4_K_M
#   export LLAMA_CLI=llama-cli
#   export LLAMA_ARGS='--ctx 2048 -t 8 --temp 0.2 --top_p 0.95 -n 512'
#   export OUTPUT_DIR=output
#   export SUMMARY_SUFFIX=.summary.txt
#   export PROMPT_TEMPLATE='Rezumă în 5 puncte, în limba română:\n\n%s'
#   export PROMPT='Rezumă în 3 puncte, în limba română:\n\n%s'  # optional override of template
#   ./summarize_outputs.sh
#
# - For other HuggingFace models, use format: organization/model-name:quantization
#   Example: Meta-Llama/Llama-3-8B-Instruct-GGUF:Q4_K_M
