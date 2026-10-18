# Build the launcher APK and install it on the TV as the default home screen. Uses a JDK 17 from
# JAVA_HOME (else Temurin 17, else Android Studio's bundled one) and the default SDK location
# unless ANDROID_HOME is set.
#
# Usage: launcher\build-and-install.ps1 [-TvHost 192.168.1.18] [-StockLauncher com.google.android.tvlauncher]
param(
    [string]$TvHost = $(if ($env:TV_HOST) { $env:TV_HOST } else { '192.168.1.18' }),
    [string]$StockLauncher = 'com.google.android.tvlauncher'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\tools\adb.ps1')
Set-Location $PSScriptRoot

if (-not $env:JAVA_HOME -or -not (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
    $jdk = @(Get-ChildItem 'C:\Program Files\Eclipse Adoptium' -Directory -Filter 'jdk-17*' -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName) +
        @(Get-ChildItem 'C:\Program Files\Android' -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'jbr' }) |
        Where-Object { Test-Path "$_\bin\java.exe" } | Select-Object -First 1
    if (-not $jdk) { throw 'Set JAVA_HOME to a JDK 17+ (winget install EclipseAdoptium.Temurin.17.JDK)' }
    $env:JAVA_HOME = $jdk
}
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
if (-not (Test-Path local.properties)) {
    "sdk.dir=$($sdk -replace '\\', '\\')" | Out-File -Encoding ascii local.properties
}

.\gradlew.bat assembleDebug -q --console=plain
if ($LASTEXITCODE -ne 0) { throw 'Gradle build failed' }

$dev = Connect-Tv $TvHost
$out = & $adb -s $dev install -r app\build\outputs\apk\debug\app-debug.apk
Write-Host $out
if ("$out" -notmatch 'Success') { throw 'install failed; the stock launcher was left untouched' }
$out = & $adb -s $dev shell cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity
Write-Host $out
if ("$out" -match 'Error') { throw 'could not set the new launcher as home; the stock launcher was left untouched' }
& $adb -s $dev shell pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION
& $adb -s $dev shell pm disable-user --user 0 $StockLauncher
Write-Host 'Installed. Press Home on the remote to see it.'
