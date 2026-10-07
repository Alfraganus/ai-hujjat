#!/usr/bin/env bash
# Downloads the embedding model used for semantic search into assets/models.
#
#   bash tool/download_model.sh
#
# Model: multilingual-e5-small (MIT, by intfloat), int8 ONNX conversion by Xenova.
# Files: model_quantized.onnx (~118 MB) and tokenizer.json (~17 MB).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
dir="$root/assets/models/multilingual-e5-small"
base="https://huggingface.co/Xenova/multilingual-e5-small/resolve/main"
mkdir -p "$dir"

fetch() { # <file name> <url>
  if [ -f "$dir/$1" ]; then echo "$1 already present, skipping"; return; fi
  echo "Downloading $1 ..."
  curl -L --fail -sS -o "$dir/$1.part" "$2"
  mv "$dir/$1.part" "$dir/$1"
}

fetch tokenizer.json "$base/tokenizer.json"
fetch model_quantized.onnx "$base/onnx/model_quantized.onnx"
echo "Done: $dir"
