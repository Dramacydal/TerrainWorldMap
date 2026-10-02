// Single place every gen_*.js/parse_wdt.js talks to wago.tools (DB2 CSVs,
// plain and per-locale) and to CASCConsole (WDT/ADT/WMO extraction from a
// local install or the Blizzard CDN). Replaces the old --flavor-dir contract
// -- callers now pass --work-dir/--client-dir|--online/--flavor and this
// module downloads/extracts exactly what's asked for into
// <work-dir>/<flavor>/, skipping anything already present unless --force.
//
// init_workdir.ps1 still owns the CASCConsole.exe tool + community listfile
// under <work-dir>/CASCConsole/ (shared across every flavor) -- this module
// only reads those, never downloads them itself.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

function flavorDir(workDir, flavor) {
	return path.join(workDir, flavor);
}

// Env-var-first config resolution (WORK_DIR/CLIENT_DIR/FLAVOR/PROXY,
// scripts/bootstrap.ps1's own job to set them) -- the env var wins whenever
// it's set to a non-empty value, argValue (whatever --work-dir/etc parsed
// off argv) is only the fallback for an ad-hoc invocation without having
// sourced bootstrap.ps1 at all. Deliberately env-over-arg, not the more
// common arg-over-env: once bootstrap.ps1 is sourced its values should just
// win every call without also having to omit the flag each time.
function envOr(argValue, envVarName) {
	const v = process.env[envVarName];
	return (v !== undefined && v !== '') ? v : argValue;
}

// <work-dir>/<flavor>/candidates/<kind>.json -- written once by
// gen_candidates.js, read by every script that used to take a positional
// map-name list (parse_wdt.js/gen_wmo_tiles.js/gen_poi_areas.js/
// gen_area_centroids.js's own --candidates <kind>). kind is one of
// continents/battlegrounds/arenas/dungeons/raids/scenarios. Each entry is
// {id, key[, expansion|uiMapID]} -- see gen_candidates.js's own header for
// the exact per-kind shape; key is Map.csv's Directory (what every
// consumer actually needs for a CASC path), id is Map.csv's ID (same as
// skip_lists.js keys on, kept for cross-referencing).
function candidatesDir(workDir, flavor) {
	return path.join(flavorDir(workDir, flavor), 'candidates');
}

function candidatesPath(workDir, flavor, kind) {
	return path.join(candidatesDir(workDir, flavor), `${kind}.json`);
}

function readCandidates(workDir, flavor, kind) {
	const p = candidatesPath(workDir, flavor, kind);
	if (!fs.existsSync(p)) {
		throw new Error(`Candidates file not found: ${p} -- run gen_candidates.js first.`);
	}
	return JSON.parse(fs.readFileSync(p, 'utf8'));
}

// Always overwrites, no existence check -- unlike downloadFile/ensureExtracted,
// there's nothing to skip: recomputing a candidate list is pure in-memory
// filtering over already-downloaded CSVs, not a CASC extraction or a
// network call, so --force only ever matters for whether gen_candidates.js's
// own ensureDb2Csv calls (Map/UiMap/UiMapAssignment) redownload those CSVs.
function writeCandidates(workDir, flavor, kind, entries) {
	const p = candidatesPath(workDir, flavor, kind);
	fs.mkdirSync(path.dirname(p), { recursive: true });
	fs.writeFileSync(p, JSON.stringify(entries, null, 2) + '\n');
	return p;
}

// Shared by every script that used to take a positional map-name list
// (parse_wdt.js/gen_wmo_tiles.js/gen_poi_areas.js/gen_area_centroids.js) --
// exactly one of --maps/--candidates is required (opts.maps: comma-split
// string already parsed by the caller's own parseArgs, opts.candidatesKind:
// the --candidates <kind> value). Comma, not space, is the separator now
// specifically so a Directory containing a space ("Stratholme Raid") no
// longer needs any special handling on the caller's side.
function resolveMapKeys({ maps, candidatesKind, workDir, flavor }) {
	if (maps && candidatesKind) {
		throw new Error('--maps and --candidates are mutually exclusive -- pass exactly one.');
	}
	if (maps) {
		return maps.split(',').map(s => s.trim()).filter(Boolean);
	}
	if (candidatesKind) {
		return readCandidates(workDir, flavor, candidatesKind).map(c => c.key);
	}
	throw new Error('One of --maps <a,b,c> or --candidates <kind> is required.');
}

function cascDir(workDir) {
	return path.join(workDir, 'CASCConsole');
}

function cascExePath(workDir) {
	return path.join(cascDir(workDir), 'CASCConsole.exe');
}

function listfilePath(workDir) {
	return path.join(cascDir(workDir), 'listfile.csv');
}

function requireCascTool(workDir) {
	const exe = cascExePath(workDir);
	const listfile = listfilePath(workDir);
	if (!fs.existsSync(exe) || !fs.existsSync(listfile)) {
		throw new Error(`CASCConsole tool/listfile not found under ${cascDir(workDir)} -- run init_workdir.ps1 -WorkDir "${workDir}" first.`);
	}
}

// -fL/--clobber only (no -s/-S) so curl's normal progress meter stays
// visible for large downloads (community listfile, WDT/ADT extraction isn't
// curl-based, but this same helper backs the Wowhead HTML fetch and every
// DB2 CSV, some of which are sizeable).
function downloadFile(url, destPath, { proxy, force, userAgent } = {}) {
	if (fs.existsSync(destPath) && !force) {
		console.error(`  already present, skipping (use --force to re-download): ${destPath}`);
		return destPath;
	}
	fs.mkdirSync(path.dirname(destPath), { recursive: true });
	const args = ['-fL', '--clobber'];
	if (proxy) args.push('-x', proxy);
	if (userAgent) args.push('-A', userAgent);
	args.push('-o', destPath, url);
	console.error(`  downloading ${url}`);
	execFileSync('curl.exe', args, { stdio: 'inherit' });
	return destPath;
}

// table: DB2 table name (Map, AreaTable, TaxiNodes, ...). locale: omit for
// the plain (locale-independent) export, e.g. 'enUS'/'deDE'/... for a
// per-locale name overlay (TaxiNodes.<locale>.csv, Map.<locale>.csv).
// Deliberately writes a stable filename (<Table>.csv / <Table>.<locale>.csv)
// instead of wago.tools' own versioned Content-Disposition name -- still
// matches csv.js's findCsv() prefix search, and makes "is this already
// downloaded" a plain existence check.
function ensureDb2Csv({ workDir, flavor, table, locale, force, proxy }) {
	const dir = flavorDir(workDir, flavor);
	const destPath = locale
		? path.join(dir, 'locales', `${table}.${locale}.csv`)
		: path.join(dir, `${table}.csv`);
	const url = locale
		? `https://wago.tools/db2/${table}/csv?product=${flavor}&locale=${locale}`
		: `https://wago.tools/db2/${table}/csv?product=${flavor}`;
	return downloadFile(url, destPath, { proxy, force });
}

// checkPaths: paths relative to the flavor dir whose presence means "already
// extracted, nothing to do" (e.g. a continent's own .wdt, a map's own
// _obj0.adt, a WMO's root file) -- skipped unless force. Otherwise shells out
// to CASCConsole.exe the same way init_workdir.ps1 used to, scoped to
// `pattern` (a Regexp -m/-e extraction pattern covering only what the caller
// actually needs). clientLocale is CASCConsole's own -l flag (client
// build/string locale, default enUS) -- unrelated to the wago.tools --locale
// used by ensureDb2Csv above.
function ensureExtracted({ workDir, flavor, clientDir, online, clientLocale, pattern, checkPaths, force }) {
	const dir = flavorDir(workDir, flavor);
	const allPresent = !force && checkPaths.length > 0 && checkPaths.every(p => fs.existsSync(path.join(dir, p)));
	if (allPresent) {
		console.error(`  already extracted, skipping (use --force to re-extract): ${checkPaths.join(', ')}`);
		return;
	}
	if (!clientDir && !online) {
		throw new Error('Extraction needed but neither --client-dir nor --online was given.');
	}
	requireCascTool(workDir);
	fs.mkdirSync(dir, { recursive: true });
	const cascArgs = ['-m', 'Regexp', '-e', pattern, '-d', dir, '-l', clientLocale || 'enUS', '-p', flavor];
	if (online) cascArgs.push('-o', 'true');
	else cascArgs.push('-s', clientDir);
	console.error(`  extracting via CASCConsole: ${pattern}`);
	execFileSync(cascExePath(workDir), cascArgs, { cwd: cascDir(workDir), stdio: 'inherit' });
}

const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Windows caps a process's own command line around 32767 chars (CreateProcess) --
// CASCConsole's own -e argument counts against that. A hand-built alternation
// over many individual paths (confirmed: gen_wmo_tiles.js's per-tile/per-group
// extraction list for a handful of large dungeons at once, 160000+ chars) blows
// past that in one shot -- ENAMETOOLONG, not a CASCConsole or logic error. Use
// this instead of building `pattern` by hand whenever the caller already has an
// explicit list of exact relative paths (not a general regex) -- chunks into
// as many CASCConsole calls as needed, each safely under the limit.
function ensureExtractedPaths({ workDir, flavor, clientDir, online, clientLocale, paths, force }) {
	const dir = flavorDir(workDir, flavor);
	const missing = force ? paths : paths.filter(p => !fs.existsSync(path.join(dir, p)));
	if (missing.length === 0) return;
	if (!clientDir && !online) {
		throw new Error('Extraction needed but neither --client-dir nor --online was given.');
	}
	requireCascTool(workDir);
	fs.mkdirSync(dir, { recursive: true });

	// Was 6000 -- way too conservative. Confirmed each CASCConsole launch
	// pays a fixed ~20s startup cost (CDN/local index + full community
	// listfile reload) regardless of how much it actually extracts, so more
	// chunks means almost pure overhead, not more work: a real run needing
	// 30 chunks at 6000 chars spent ~10 of its ~15 minutes on nothing but
	// repeated startup. 25000 leaves ~7500 chars of headroom under the
	// ~32767 Windows command-line cap for the rest of argv (exe path, -m/-e/
	// -d/-l/-p/-s and their values -- a few hundred chars at most).
	const MAX_PATTERN_CHARS = 25000;
	const chunks = [];
	let chunk = [], chunkLen = 0;
	for (const p of missing) {
		const esc = escapeRegExp(p);
		if (chunk.length > 0 && chunkLen + esc.length + 1 > MAX_PATTERN_CHARS) {
			chunks.push(chunk);
			chunk = []; chunkLen = 0;
		}
		chunk.push(esc);
		chunkLen += esc.length + 1;
	}
	if (chunk.length > 0) chunks.push(chunk);

	chunks.forEach((c, i) => {
		const pattern = `^(${c.join('|')})$`;
		const cascArgs = ['-m', 'Regexp', '-e', pattern, '-d', dir, '-l', clientLocale || 'enUS', '-p', flavor];
		if (online) cascArgs.push('-o', 'true');
		else cascArgs.push('-s', clientDir);
		console.error(`  extracting via CASCConsole: ${c.length} path(s) (chunk ${i + 1}/${chunks.length})`);
		execFileSync(cascExePath(workDir), cascArgs, { cwd: cascDir(workDir), stdio: 'inherit' });
	});
}

// Extracts files by FileDataID (CASCConsole -m FileDataId, comma-separated
// list in one call) -- the way to get a file whose ID is known (e.g. from a
// DB2 table) but whose name is not in the community listfile yet. CASCConsole
// writes a named file to its own path and an unnamed one to
// `unknown/FILEDATA_<id>` (no extension), so each entry carries the relative
// path (to the flavor dir) where that file is expected afterwards; entries
// whose file is already there are skipped unless force. An ID the build does
// not contain just never produces a file (CASCConsole prints "not found in
// root") and is retried on the next run.
// files: [{id, rel}]
function ensureExtractedFileDataIds({ workDir, flavor, clientDir, online, clientLocale, files, force }) {
	const dir = flavorDir(workDir, flavor);
	const missing = force ? files : files.filter(f => !fs.existsSync(path.join(dir, f.rel)));
	if (missing.length === 0) return;
	if (!clientDir && !online) {
		throw new Error('Extraction needed but neither --client-dir nor --online was given.');
	}
	requireCascTool(workDir);
	fs.mkdirSync(dir, { recursive: true });

	// Same ~32767-char Windows command-line cap as ensureExtractedPaths,
	// and the same ~20s fixed startup cost per CASCConsole launch.
	const MAX_ARG_CHARS = 25000;
	const chunks = [];
	let chunk = [], chunkLen = 0;
	for (const f of missing) {
		const s = String(f.id);
		if (chunk.length > 0 && chunkLen + s.length + 1 > MAX_ARG_CHARS) {
			chunks.push(chunk);
			chunk = []; chunkLen = 0;
		}
		chunk.push(s);
		chunkLen += s.length + 1;
	}
	if (chunk.length > 0) chunks.push(chunk);

	chunks.forEach((c, i) => {
		const cascArgs = ['-m', 'FileDataId', '-e', c.join(','), '-d', dir, '-l', clientLocale || 'enUS', '-p', flavor];
		if (online) cascArgs.push('-o', 'true');
		else cascArgs.push('-s', clientDir);
		console.error(`  extracting via CASCConsole by FileDataID: ${c.length} file(s) (chunk ${i + 1}/${chunks.length})`);
		execFileSync(cascExePath(workDir), cascArgs, { cwd: cascDir(workDir), stdio: 'inherit' });
	});
}

module.exports = {
	flavorDir,
	cascDir,
	cascExePath,
	listfilePath,
	requireCascTool,
	downloadFile,
	ensureDb2Csv,
	ensureExtracted,
	ensureExtractedPaths,
	ensureExtractedFileDataIds,
	envOr,
	candidatesDir,
	candidatesPath,
	readCandidates,
	writeCandidates,
	resolveMapKeys,
};
