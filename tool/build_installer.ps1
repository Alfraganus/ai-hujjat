# Builds the release app and packs it into dist\AI_Hujjat_Setup_<version>.exe
#
#   powershell -ExecutionPolicy Bypass -File tool\build_installer.ps1
#
# Needs: Flutter, Inno Setup 6 (winget install JRSoftware.InnoSetup).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$version = ((Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)').Matches[0].Groups[1].Value)
Write-Host "Version $version"

flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }

# Flutter apps need the Visual C++ runtime; ship it next to the exe so a clean
# Windows install does not depend on a separately installed redistributable.
$release = Join-Path $root 'build\windows\x64\runner\Release'
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    $src = Join-Path $env:WINDIR "System32\$dll"
    if (Test-Path $src) { Copy-Item $src $release -Force } else { Write-Warning "$dll not found; installer will rely on the system runtime" }
}

# Wizard artwork lives in installer\ (committed). Regenerate only if missing:
# needs Python with Pillow; `python` may be the Microsoft Store stub, so try `py` first.
if (-not (Test-Path installer\wizard_large.bmp)) {
    $env:ICON_GEN = '1'
    flutter test test/icon_gen_test.dart | Out-Null
    $py = @('py', 'python') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
    if (-not $py) { throw 'installer\wizard_large.bmp is missing and Python was not found to regenerate it.' }
    & $py tool\make_installer_art.py
    if ($LASTEXITCODE -ne 0) { throw 'make_installer_art.py failed (needs: pip install pillow)' }
}

$iscc = @(
    "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 not found. Install it with: winget install JRSoftware.InnoSetup' }

& $iscc "/DAppVersion=$version" installer\ai_hujjat.iss
if ($LASTEXITCODE -ne 0) { throw 'ISCC failed' }
Write-Host "Done: dist\AI_Hujjat_Setup_$version.exe"
