#Requires -Version 7.0
<#
.SYNOPSIS
	Prepares a WORKDIR with everything gen_mapareas.js / parse_wdt.js / gen_poi_instances.js /
	gen_poi_flightmasters.js need for one WoW product: DB2 CSVs (AreaTable/Map/UiMap/
	UiMapAssignment/AreaTrigger/TaxiNodes/TaxiPath) + extracted WDT/root-ADT/noLiquid-minimap
	files.

.PARAMETER Product
	TACT product code, e.g. wow_classic_era, wow_anniversary, wow_classic (see .build.info).

.PARAMETER WorkDir
	Root working directory. Gets WorkDir/CASCConsole (tool, shared across products)
	and WorkDir/<Product> (per-product DB2 CSVs + extracted game files).

.PARAMETER Online
	Use CASCConsole's online mode (pulls from Blizzard CDN) instead of a local install.

.PARAMETER Storage
	Path to a local WoW installation root. Required unless -Online is set.

.PARAMETER Proxy
	Optional proxy, passed straight through to curl.exe's -x/--proxy option.
	Format: scheme://[user:password@]host[:port] -- scheme is one of
	http, https, socks4, socks4a, socks5, socks5h (the h suffix resolves
	DNS through the proxy too; use it for SOCKS5 unless you have a reason not to).
	Example: socks5h://user:pass@127.0.0.1:8883
	Not hardcoded here on purpose -- this file is git-tracked.

.EXAMPLE
	./init_workdir.ps1 -Product wow_classic -Online -WorkDir E:\wow-data
.EXAMPLE
	./init_workdir.ps1 -Product wow_anniversary -Storage "C:\Program Files\World of Warcraft" -WorkDir E:\wow-data -Proxy socks5h://user:pass@127.0.0.1:8883
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[string]$Product,

	[Parameter(Mandatory)]
	[string]$WorkDir,

	[switch]$Online,

	[string]$Storage,

	[string]$Region = 'eu',

	[string]$Locale = 'enUS',

	# curl.exe -x/--proxy format: scheme://[user:password@]host[:port]
	[ValidatePattern('^(https?|socks[45]h?)://([^:@/]+:[^:@/]+@)?[^/@]+(:\d+)?$', ErrorMessage = "Proxy must be in curl's --proxy format, e.g. socks5h://user:pass@127.0.0.1:8883")]
	[string]$Proxy,

	[switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not $Online -and [string]::IsNullOrWhiteSpace($Storage)) {
	throw "Either -Online or -Storage <path to WoW install> must be specified."
}
if ($Online -and $Storage) {
	Write-Warning "-Storage is ignored when -Online is set."
}

$CASCCONSOLE_URL = 'https://github.com/Dramacydal/CASCExplorer/releases/download/build-latest/CASCConsole.zip'
$LISTFILE_URL = 'https://github.com/wowdev/wow-listfile/releases/latest/download/community-listfile.csv'
$DB2_TABLES = @('AreaTable', 'Map', 'UiMap', 'UiMapAssignment', 'AreaTrigger', 'TaxiNodes', 'TaxiPath')

$scriptsDir = $PSScriptRoot
$cascDir = Join-Path $WorkDir 'CASCConsole'
$productDir = Join-Path $WorkDir $Product

New-Item -ItemType Directory -Force -Path $cascDir | Out-Null
New-Item -ItemType Directory -Force -Path $productDir | Out-Null

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

Step "DB2 CSVs (AreaTable/Map/UiMap/UiMapAssignment/AreaTrigger/TaxiNodes/TaxiPath)" {
	$haveAll = -not $Force -and ($DB2_TABLES | ForEach-Object {
		Get-ChildItem -Path $productDir -Filter "$_*.csv" -ErrorAction SilentlyContinue
	} | Measure-Object).Count -ge $DB2_TABLES.Count
	if ($haveAll) {
		Write-Host "    already present, skipping (use -Force to re-download)"
		return
	}
	foreach ($table in $DB2_TABLES) {
		$url = "https://wago.tools/db2/$table/csv?product=$Product"
		Invoke-Curl @('-J', '-O', '--output-dir', $productDir, $url)
	}
}

$continents = $null
Step "Continent list (gen_mapareas.js)" {
	$genScript = Join-Path $scriptsDir 'gen_mapareas.js'
	$lines = & node $genScript $productDir 2>$null
	if ($LASTEXITCODE -ne 0 -or -not $lines) {
		throw "gen_mapareas.js failed to produce a continent list -- check DB2 CSVs in $productDir"
	}
	$script:continents = ($lines | Select-Object -First 1) -split '\s+' | Where-Object { $_ }
	Write-Host "    $($continents.Count) continents: $($continents -join ', ')"
}

$pattern = $null
Step "Build extraction regex" {
	$escaped = $continents | ForEach-Object { [regex]::Escape($_) }
	$contAlt = $escaped -join '|'
	$script:pattern = "^world/(maps/($contAlt)/([^_/]+\.wdt|\w+_\d+_\d+\.adt)|minimaps/($contAlt)/noliquid_map\d+_\d+\.blp)$"
	Write-Host "    $pattern"
}

Step "Extract WDT/ADT/minimap files via CASCConsole" {
	Push-Location $cascDir
	try {
		$cascArgs = @('-m', 'Regexp', '-e', $pattern, '-d', $productDir, '-l', $Locale, '-p', $Product)
		if ($Online) {
			$cascArgs += @('-o', 'true')
		} else {
			$cascArgs += @('-s', $Storage)
		}
		& .\CASCConsole.exe @cascArgs
		if ($LASTEXITCODE -ne 0) {
			throw "CASCConsole.exe exited with code $LASTEXITCODE"
		}
	} finally {
		Pop-Location
	}
}

$extractedCount = (Get-ChildItem -Path (Join-Path $productDir 'world') -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host ""
Write-Host "Done. $extractedCount files extracted into $productDir" -ForegroundColor Green
Write-Host "Pass '$productDir' as --flavor-dir to parse_wdt.js and as the <csv-dir> argument to gen_mapareas.js."
