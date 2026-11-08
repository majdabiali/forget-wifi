<#
.SYNOPSIS
  forget-wifi.ps1 - forget saved Wi-Fi networks before a conference or trip (Windows).

.DESCRIPTION
  Your laptop silently auto-joins any network that broadcasts a name it has
  saved ("Starbucks", "Hotel_Guest", "Airport Free WiFi"...). An attacker at a
  conference only needs to guess one of them to get you onto their network.
  This forgets every saved network except the ones you choose to keep.
  The network you're connected to is kept automatically.

.EXAMPLE
  .\forget-wifi.ps1 -DryRun
  .\forget-wifi.ps1 -Keep "Home WiFi","My iPhone"

.NOTES
  Run from an Administrator PowerShell. SPDX-License-Identifier: MIT
#>
[CmdletBinding()]
param(
  [Alias('n')][switch]$DryRun,   # only list what would be forgotten
  [Alias('y')][switch]$Yes,      # don't ask for confirmation
  [Alias('k')][string[]]$Keep = @()
)

# "    All User Profile     : Name" - the label is localised, the layout isn't.
$saved = @(netsh wlan show profiles | ForEach-Object {
  if ($_ -match '^\s{4}\S.*?\s+:\s(.+?)\s*$') { $Matches[1] }
})
$current = netsh wlan show interfaces | ForEach-Object {
  if ($_ -match '^\s+Profile\s+:\s(.+?)\s*$') { $Matches[1] }
} | Select-Object -First 1

if ($current) { $Keep += $current }
$forget = @($saved | Where-Object { $Keep -notcontains $_ })

if ($forget.Count -eq 0) { Write-Host "Nothing to forget."; exit 0 }
$forget | ForEach-Object { Write-Host "  $_" }
Write-Host "$($forget.Count) saved networks will be forgotten."
if ($Keep.Count) { Write-Host "Keeping: $($Keep -join ', ')" }
if (-not $current) { Write-Host "Note: couldn't detect the network you're on. If it's listed above, re-run with -Keep `"its name`" to keep it." }

if ($DryRun) { Write-Host "(dry run, nothing changed)"; exit 0 }
$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Run PowerShell as Administrator to forget networks."; exit 1
}
if (-not $Yes -and (Read-Host "Forget them? [y/N]") -notmatch '^[yY]$') { Write-Host "Nothing changed."; exit 0 }

$fail = 0
foreach ($p in $forget) {
  netsh wlan delete profile name="$p" | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host "forgot: $p" } else { Write-Host "FAILED: $p"; $fail = 1 }
}
Write-Host ""
Write-Host "Done. Also clean your phone: iPhone Settings > Wi-Fi > Edit; Android Settings > Network > Saved networks."
exit $fail
