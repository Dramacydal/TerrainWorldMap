// Shared CSV reading for gen_mapareas.js/parse_wdt.js -- DBC-export CSVs
// (comma-separated, quoted fields, header row = column names). Uses the
// `csv-parse` npm package (RFC 4180-compliant). Run `npm install` in this
// `scripts/` folder once before use.
const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');

// Row objects keyed by the CSV's header row, e.g. { ID: '0', Directory:
// 'Azeroth', ... }. Values are always strings; callers parseInt/parseFloat.
function parseCsvFile(filePath) {
	const text = fs.readFileSync(filePath, 'utf8');
	return parse(text, { columns: true, skip_empty_lines: true });
}

// wow.export names DBC exports "<Table>.<client-version>.<build>.csv" (e.g.
// "Map.5.5.4.69155.csv") -- the version/build suffix varies per client, so
// match by table-name prefix instead of requiring the exact filename.
function findCsv(dir, prefix) {
	const match = fs.readdirSync(dir).find(f => f.toLowerCase().startsWith(prefix.toLowerCase()) && f.toLowerCase().endsWith('.csv'));
	if (!match)
		throw new Error(`No ${prefix}*.csv found in ${dir}`);
	return path.join(dir, match);
}

module.exports = { parseCsvFile, findCsv };
