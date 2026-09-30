#Requires -Version 7.0
<#
.SYNOPSIS
	Prepares a WORKDIR with the tools every gen_*.js/parse_wdt.js script needs
	to self-extract its own data: the CASCConsole tool and the community
	listfile, both shared across every flavor. Does NOT download any
	product-specific data (DB2 CSVs, WDT/ADT/WMO files, locale exports) --
	each script now fetches/extracts exactly what it needs itself into
	<WorkDir>/<flavor>/ via scripts/extract.js, given --work-dir,
	--client-dir (or --online) and --flavor.

.PARAMETER WorkDir
	Root working directory. Gets WorkDir/CASCConsole (tool + listfile) --
	every gen_*.js/parse_wdt.js script reads this directly via --work-dir.

.PARAMETER Proxy
	Optional proxy, passed straight through to curl.exe's -x/--proxy option.
	Format: scheme://[user:password@]host[:port] -- scheme is one of
	http, https, socks4, socks4a, socks5, socks5h (the h suffix resolves
	DNS through the proxy too; use it for SOCKS5 unless you have a reason not to).
	Example: socks5h://user:pass@127.0.0.1:8883
	Not hardcoded here on purpose -- this file is git-tracked.

.EXAMPLE
	./init_workdir.ps1 -WorkDir E:\wow-data
.EXAMPLE
	./init_workdir.ps1 -WorkDir E:\wow-data -Proxy socks5h://user:pass@127.0.0.1:8883
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[string]$WorkDir,

	# curl.exe -x/--proxy format: scheme://[user:password@]host[:port]
	[ValidatePattern('^(https?|socks[45]h?)://([^:@/]+:[^:@/]+@)?[^/@]+(:\d+)?$', ErrorMessage = "Proxy must be in curl's --proxy format, e.g. socks5h://user:pass@127.0.0.1:8883")]
	[string]$Proxy,

	[switch]$Force
)

$ErrorActionPreference = 'Stop'

$CASCCONSOLE_URL = 'https://github.com/Dramacydal/CASCExplorer/releases/download/build-latest/CASCConsole.zip'
$LISTFILE_URL = 'https://github.com/wowdev/wow-listfile/releases/latest/download/community-listfile.csv'

$cascDir = Join-Path $WorkDir 'CASCConsole'
New-Item -ItemType Directory -Force -Path $cascDir | Out-Null

$curlProxyArgs = @()
if ($Proxy) {
	$curlProxyArgs = @('-x', $Proxy)
}

function Invoke-Curl {
	param([string[]]$CurlArgs)
	# -f/-L only (no -s/-S) so curl's normal progress meter stays visible --
	# the listfile download alone is ~150MB and looks like a hang otherwise.
	# --clobber: re-running this script (e.g. after an earlier failed step)
	# must overwrite partial/stale downloads, not error out on "File exists".
	& curl.exe -fL --clobber @curlProxyArgs @CurlArgs
	if ($LASTEXITCODE -ne 0) {
		throw "curl.exe failed (exit $LASTEXITCODE) for args: $($CurlArgs -join ' ')"
	}
}

function Step {
	param([string]$Title, [scriptblock]$Body)
	Write-Host "==> $Title" -ForegroundColor Cyan
	$sw = [System.Diagnostics.Stopwatch]::StartNew()
	& $Body
	Write-Host "    done in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor DarkGray
}

Step "CASCConsole tool" {
	$exePath = Join-Path $cascDir 'CASCConsole.exe'
	if ((Test-Path $exePath) -and -not $Force) {
		Write-Host "    already present, skipping (use -Force to re-download)"
		return
	}
	$zipPath = Join-Path $cascDir 'CASCConsole.zip'
	Invoke-Curl @('-o', $zipPath, $CASCCONSOLE_URL)
	Expand-Archive -Path $zipPath -DestinationPath $cascDir -Force
	Remove-Item $zipPath
}

Step "Community listfile" {
	$listfilePath = Join-Path $cascDir 'listfile.csv'
	if ((Test-Path $listfilePath) -and -not $Force) {
		Write-Host "    already present, skipping (use -Force to re-download)"
		return
	}
	Invoke-Curl @('-o', $listfilePath, $LISTFILE_URL)
}

Write-Host ""
Write-Host "Done. Tools ready under $cascDir" -ForegroundColor Green
Write-Host "Pass '$WorkDir' as --work-dir to every gen_*.js/parse_wdt.js script, along with --flavor <product> and --client-dir <path>|--online."
