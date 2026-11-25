param([string]$Url = '')
# Keeps the landing page pointing at the live app URL.
# Called by nudge-check-once.cmd every cycle; only writes when the URL changed.
# NOTE: file is saved with a UTF-8 BOM on purpose so PowerShell 5.1 always
# parses it as UTF-8, and reads/writes use explicit UTF-8 so symbols like
# the em-dash and arrows in index.html are never mangled.
if (-not $Url) { exit 0 }
$p = Join-Path $PSScriptRoot 'landing'
$i = Join-Path $p 'index.html'
$c = Join-Path $p 'config.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
try {
  if (Test-Path $i) {
    $t = [System.IO.File]::ReadAllText($i, [System.Text.Encoding]::UTF8)
    # Safety guard: if the em-dash (U+2014) is gone the decode went wrong -
    # abort instead of writing corrupted symbols.
    if (-not $t.Contains([string][char]0x2014)) {
      Write-Output 'landing sync ABORTED: index.html decode check failed'
      exit 1
    }
    if ($t -notmatch [regex]::Escape($Url)) {
      $t = $t -replace 'window\.NUDGE_APP_URL\s*=\s*"[^"]*"', ('window.NUDGE_APP_URL = "' + $Url + '"')
      [System.IO.File]::WriteAllText($i, $t, $utf8NoBom)
      Write-Output "landing/index.html -> $Url"
    }
  }
  if (Test-Path $c) {
    $j = [System.IO.File]::ReadAllText($c, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($j.appUrl -ne $Url) {
      $j.appUrl = $Url
      [System.IO.File]::WriteAllText($c, ($j | ConvertTo-Json -Compress), $utf8NoBom)
      Write-Output "landing/config.json -> $Url"
    }
  }
} catch { Write-Output "landing sync skipped: $_" }
