param(
  [string]$AppDir = "flutter_app",
  [string]$ProjectName = "sql_pancake_flutter"
)

$ErrorActionPreference = "Stop"

function Assert-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Required command '$name' not found in PATH. Install it first (Flutter SDK), then re-run."
  }
}

Write-Host "== SQL-pancake Flutter setup =="
Assert-Command flutter

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$templateDir = Join-Path $repoRoot "flutter_template"
$appPath = Join-Path $repoRoot $AppDir

if (-not (Test-Path $templateDir)) {
  throw "Template not found: $templateDir"
}

if (-not (Test-Path $appPath)) {
  Write-Host "Creating Flutter project in: $appPath"
  flutter create --project-name $ProjectName $appPath
} else {
  Write-Host "Using existing app folder: $appPath"
}

# Copy template files
Write-Host "Copying template lib/ and assets/"
New-Item -ItemType Directory -Force (Join-Path $appPath "lib") | Out-Null
Copy-Item -Force (Join-Path $templateDir "lib\*") (Join-Path $appPath "lib")

New-Item -ItemType Directory -Force (Join-Path $appPath "assets\schemas") | Out-Null
Copy-Item -Force (Join-Path $repoRoot "examples\*.sql") (Join-Path $appPath "assets\schemas")

# Patch pubspec.yaml: add deps + assets
$pubspec = Join-Path $appPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) {
  throw "pubspec.yaml not found: $pubspec"
}

$yaml = Get-Content $pubspec -Raw

# Ensure dependencies
if ($yaml -notmatch "\n\s*sqflite:") {
  $yaml = $yaml -replace "(?ms)(^dependencies:\s*\n)", "`$1  sqflite: ^2.3.3+1`n  path: ^1.9.0`n  path_provider: ^2.1.4`n"
}

# Ensure assets section
if ($yaml -notmatch "(?ms)^flutter:\s*\n") {
  throw "Unexpected pubspec.yaml format (missing 'flutter:' section)."
}

if ($yaml -notmatch "(?ms)^flutter:\s*\n[\s\S]*?^\s*assets:\s*\n") {
  $yaml = $yaml -replace "(?ms)(^flutter:\s*\n)", "`$1  assets:`n    - assets/schemas/`n"
} elseif ($yaml -notmatch "assets/schemas/") {
  $yaml = $yaml -replace "(?ms)(^\s*assets:\s*\n)", "`$1    - assets/schemas/`n"
}

Set-Content -Path $pubspec -Value $yaml -Encoding UTF8

Write-Host "Running flutter pub get"
Push-Location $appPath
flutter pub get
Pop-Location

Write-Host "Done. Next:" 
Write-Host "  cd $AppDir"
Write-Host "  flutter run"
Write-Host "  flutter build apk"
