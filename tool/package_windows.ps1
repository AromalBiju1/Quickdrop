param(
  [string]$Version = ""
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if ([string]::IsNullOrWhiteSpace($Version)) {
  $pubspec = Get-Content (Join-Path $Root "pubspec.yaml") |
    Where-Object { $_ -match '^version:\s*(\S+)' } |
    Select-Object -First 1
  if (-not $pubspec) {
    throw "Could not determine the version from pubspec.yaml."
  }
  $null = $pubspec -match '^version:\s*(\S+)'
  $Version = $Matches[1].Split("+")[0]
}

$Bundle = Join-Path $Root "build\windows\x64\runner\Release"
$Executable = Join-Path $Bundle "quickdrop.exe"
if (-not (Test-Path $Executable)) {
  throw "Windows release bundle not found. Run: flutter build windows --release"
}

$StageRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
$Stage = Join-Path $StageRoot "quickdrop-windows-package"
$PackageName = "QuickDrop-$Version-windows-x64"
$PackageDir = Join-Path $Stage $PackageName

try {
  if (Test-Path $Stage) {
    Remove-Item -Recurse -Force $Stage
  }
  New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null
  Copy-Item -Path (Join-Path $Bundle "*") -Destination $PackageDir -Recurse -Force
  Copy-Item (Join-Path $Root "packaging\windows\README.txt") (Join-Path $PackageDir "README.txt")

  $ReleaseDir = Join-Path $Root "release"
  New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
  $Artifact = Join-Path $ReleaseDir "$PackageName.zip"
  $Checksum = "$Artifact.sha256"
  Remove-Item -Force $Artifact, $Checksum -ErrorAction SilentlyContinue

  Compress-Archive -Path $PackageDir -DestinationPath $Artifact -CompressionLevel Optimal
  $Hash = (Get-FileHash -Algorithm SHA256 $Artifact).Hash.ToLowerInvariant()
  "$Hash  $([IO.Path]::GetFileName($Artifact))" |
    Set-Content -Path $Checksum -Encoding ascii

  Write-Output "Created $Artifact"
  Get-Content $Checksum
} finally {
  if (Test-Path $Stage) {
    Remove-Item -Recurse -Force $Stage
  }
}
