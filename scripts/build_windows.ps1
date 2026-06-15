param(
  [switch]$SkipTests,
  [switch]$UseGlobalPubCache,
  [switch]$Clean,
  [string]$AppVersion = ""
)

$ErrorActionPreference = "Stop"

$isWindowsHost = $env:OS -eq "Windows_NT" -or
  $PSVersionTable.Platform -eq "Win32NT" -or
  $IsWindows

if (-not $isWindowsHost) {
  Write-Error "Windows desktop builds must run on a Windows host. Run this script in Windows PowerShell or PowerShell 7 on Windows."
}

$projectRoot = Get-Location

if ([string]::IsNullOrWhiteSpace($AppVersion)) {
  $AppVersion = $env:SPONZEY_APP_VERSION
}

if ([string]::IsNullOrWhiteSpace($AppVersion)) {
  $versionLine = Select-String -Path (Join-Path $projectRoot "pubspec.yaml") -Pattern "^version:\s*(.+)$" | Select-Object -First 1
  if ($null -ne $versionLine) {
    $AppVersion = $versionLine.Matches[0].Groups[1].Value.Trim()
  }
}

if ([string]::IsNullOrWhiteSpace($AppVersion)) {
  Write-Error "Unable to determine app version. Pass -AppVersion or set SPONZEY_APP_VERSION."
}

if (-not $UseGlobalPubCache) {
  $localPubCache = Join-Path $projectRoot ".dart_tool\pub-cache"
  New-Item -ItemType Directory -Force -Path $localPubCache | Out-Null
  $env:PUB_CACHE = $localPubCache
  Write-Host "Using project-local PUB_CACHE: $localPubCache"
}

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [scriptblock]$Command
  )

  Write-Host ""
  Write-Host "==> $Name"
  & $Command
}

Invoke-Step "Flutter version" { flutter --version }
Invoke-Step "Enable Windows desktop" { flutter config --enable-windows-desktop }

if ($Clean) {
  Invoke-Step "Clean generated build files" { flutter clean }
}

Invoke-Step "Resolve dependencies" { flutter pub get }
Invoke-Step "Analyze" { flutter analyze }

if (-not $SkipTests) {
  Invoke-Step "Test" { flutter test --concurrency=1 --reporter expanded }
}

Invoke-Step "Build Windows release" {
  flutter build windows --release "--dart-define=SPONZEY_APP_VERSION=$AppVersion"
}

$artifact = Join-Path (Get-Location) "build\windows\x64\runner\Release"

Write-Host ""
Write-Host "Windows release output:"
Write-Host $artifact
