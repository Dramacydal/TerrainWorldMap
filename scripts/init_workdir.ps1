#Requires -Version 7.0
<#
.SYNOPSIS
	Prepares a WORKDIR with the tools every gen_*.js/parse_wdt.js script needs
	to self-extract its own data: the CASCConsole tool, the community
	listfile and the TACT keys (TactKey.csv, read by CASCConsole from its own
	folder -- without a key CASCConsole cannot extract the files encrypted with
	it, "unknown keyname"), all shared across every flavor. Does NOT download any
	product-specific data (DB2 CSVs, WDT/ADT/WMO files, locale exports) --
	each script now fetches/extracts exactly what it needs itself into
	<WorkDir>/<flavor>/ via scripts/extract.js, given --work-dir,
	--client-dir (or --online) and --flavor.

.PARAMETER WorkDir
	Root working directory. Gets WorkDir/CASCConsole (tool + listfile + TactKey.csv) --
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
$TACTKEYS_URL = 'https://raw.githubusercontent.com/wowdev/TACTKeys/master/WoW.txt'

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
	# Downloaded to a temporary file and renamed over listfile.csv only once curl succeeded: a failed
	# or interrupted download (the file is ~150MB) must not leave a truncated listfile that the
	# "already present" check above would then accept as good.
	$listfileTmp = "$listfilePath.part"
	try {
		Invoke-Curl @('-o', $listfileTmp, $LISTFILE_URL)
		Move-Item -Path $listfileTmp -Destination $listfilePath -Force
	} finally {
		Remove-Item -Path $listfileTmp -ErrorAction SilentlyContinue
	}
}

# CASCConsole (CascLib's KeyService.LoadKeys) reads TactKey.csv from the folder it runs in,
# one "<16 hex key name>;<32 hex key>" per line, on top of the keys compiled into CascLib.dll.
# A key a client build needs but CascLib.dll lacks shows up as "Error (unknown keyname ...)"
# for the files it protects (new maps' WDT/ADT in a fresh Forever build were such). The list
# is small and only grows with the builds, so it is fetched on every run (not skipped like the
# tool and the listfile). Everything is written to temporary files and TactKey.csv is only
# replaced (renamed over) once the download and the conversion succeeded, so a failure at any
# point leaves the previous TactKey.csv as it was (or none), never a broken one.
Step "TACT keys" {
	$keysPath = Join-Path $cascDir 'TactKey.csv'
	$txtTmp = Join-Path $cascDir 'WoW.txt.part'
	$csvTmp = Join-Path $cascDir 'TactKey.csv.part'
	try {
		Invoke-Curl @('-o', $txtTmp, $TACTKEYS_URL)
		# "NAME KEY [comment]" -> "NAME;KEY"
		$lines = foreach ($line in Get-Content $txtTmp) {
			if ($line -match '^([0-9A-Fa-f]{16})\s+([0-9A-Fa-f]{32})\b') {
				"$($Matches[1].ToUpper());$($Matches[2].ToUpper())"
			}
		}
		if (-not $lines) {
			throw "No keys found in the download -- the format of $TACTKEYS_URL changed?"
		}
		Set-Content -Path $csvTmp -Value $lines -Encoding ascii
		Move-Item -Path $csvTmp -Destination $keysPath -Force
		Write-Host "    $(@($lines).Count) keys written to TactKey.csv"
	} catch {
		if (-not (Test-Path $keysPath)) { throw }
		Write-Warning "TACT keys update failed, keeping the existing TactKey.csv: $($_.Exception.Message)"
	} finally {
		Remove-Item -Path $txtTmp, $csvTmp -ErrorAction SilentlyContinue
	}
}

Write-Host ""
Write-Host "Done. Tools ready under $cascDir" -ForegroundColor Green
Write-Host "Pass '$WorkDir' as --work-dir to every gen_*.js/parse_wdt.js script, along with --flavor <product> and --client-dir <path>|--online."
