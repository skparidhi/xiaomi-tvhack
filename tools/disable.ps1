# Disable every package listed in a debloat file on the TV (one package per line, # comments allowed).
# Packages are disabled for user 0, never uninstalled. Undo with tools\restore.ps1 <same file>.
# Uses the adb binary (winget install Google.PlatformTools), one pm command per shell call.
#
# Usage: tools\disable.ps1 -TvHost 192.168.1.18 examples\xiaomi-mitv4i\debloat.txt
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$List,
    [string]$TvHost = $(if ($env:TV_HOST) { $env:TV_HOST } else { '192.168.1.18' })
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'adb.ps1')
$dev = Connect-Tv $TvHost

$pkgs = Get-Content $List | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ }
foreach ($p in $pkgs) { "{0,-45} {1}" -f $p, (& $adb -s $dev shell pm disable-user --user 0 $p) }
"--- disabled now ---"
& $adb -s $dev shell pm list packages -d
