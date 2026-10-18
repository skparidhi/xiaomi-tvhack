# Re-enable every package listed in a debloat file, restore the stock launcher as home and reset
# animation scales. Pass the same list you used with disable.ps1.
#
# Usage: tools\restore.ps1 -TvHost 192.168.1.18 examples\xiaomi-mitv4i\debloat.txt [-Stock stock.launcher.package]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$List,
    [string]$Stock = 'com.google.android.tvlauncher',
    [string]$TvHost = $(if ($env:TV_HOST) { $env:TV_HOST } else { '192.168.1.18' })
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'adb.ps1')
$dev = Connect-Tv $TvHost

$pkgs = Get-Content $List | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ }
foreach ($p in $pkgs + $Stock) { "{0,-45} {1}" -f $p, (& $adb -s $dev shell pm enable $p) }
& $adb -s $dev shell cmd package set-home-activity --user 0 $Stock
foreach ($k in 'window_animation_scale', 'transition_animation_scale', 'animator_duration_scale') {
    & $adb -s $dev shell settings put global $k 1.0
}
"--- still disabled ---"
& $adb -s $dev shell pm list packages -d
