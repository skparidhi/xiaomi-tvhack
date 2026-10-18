# Shared helper, dot-sourced by the other scripts: finds adb.exe and connects to the TV.
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) {
    $adb = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter adb.exe -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $adb) { throw 'adb not found: winget install Google.PlatformTools' }

function Connect-Tv([string]$TvHost) {
    $dev = "${TvHost}:5555"
    & $adb connect $dev | Out-Null
    $state = & $adb -s $dev get-state 2>$null
    if ($state -ne 'device') { throw "TV at $dev is '$state': turn on USB debugging and accept the prompt on the TV" }
    $dev
}
