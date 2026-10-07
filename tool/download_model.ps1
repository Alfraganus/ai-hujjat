# Downloads the embedding model used for semantic search into assets\models.
#
#   powershell -ExecutionPolicy Bypass -File tool\download_model.ps1
#
# Model: multilingual-e5-small (MIT, by intfloat), int8 ONNX conversion by Xenova.
#   https://huggingface.co/intfloat/multilingual-e5-small
#   https://huggingface.co/Xenova/multilingual-e5-small
# Files: model_quantized.onnx (~118 MB) and tokenizer.json (~17 MB).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root 'assets\models\multilingual-e5-small'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$base = 'https://huggingface.co/Xenova/multilingual-e5-small/resolve/main'
$files = @{
    'tokenizer.json'       = "$base/tokenizer.json"
    'model_quantized.onnx' = "$base/onnx/model_quantized.onnx"
}

foreach ($name in $files.Keys) {
    $target = Join-Path $dir $name
    if (Test-Path $target) { Write-Host "$name already present, skipping"; continue }
    Write-Host "Downloading $name ..."
    $tmp = "$target.part"
    Invoke-WebRequest -Uri $files[$name] -OutFile $tmp -UseBasicParsing
    Move-Item $tmp $target
}
Write-Host "Done: $dir"
