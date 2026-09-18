param(
    [Parameter(Mandatory=$true)][string]$ApiBaseUrl,
    [Parameter(Mandatory=$true)][string]$ApplicationId,
    [Parameter(Mandatory=$true)][string]$GoogleOAuthClientId
)
$ErrorActionPreference = 'Stop'
if ($ApiBaseUrl -notmatch '^https://[^/]+/api/v1/$') { throw 'Use an HTTPS API URL ending in /api/v1/.' }
if ($ApplicationId -notmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$' -or $ApplicationId.StartsWith('com.example.')) {
    throw 'Supply your permanent Android application ID.'
}
if (-not (Test-Path -LiteralPath "$PSScriptRoot/android/key.properties")) { throw 'Configure android/key.properties first.' }
Push-Location $PSScriptRoot
try {
    $previousApplicationId = $env:ORG_GRADLE_PROJECT_applicationId
    $env:ORG_GRADLE_PROJECT_applicationId = $ApplicationId
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Analysis failed.' }
    flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    flutter build appbundle --release "--dart-define=API_BASE_URL=$ApiBaseUrl" "--dart-define=GOOGLE_OAUTH_CLIENT_ID=$GoogleOAuthClientId" --obfuscate --split-debug-info=build/symbols
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
} finally {
    $env:ORG_GRADLE_PROJECT_applicationId = $previousApplicationId
    Pop-Location
}
