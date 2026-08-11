// Shared CSV reading for the data-generation scripts (gen_mapareas.js,
// parse_wdt.js) -- all of them read the same wow.export DBC-export CSV
// shape (comma-separated, quoted fields, header row = column names).
//
// Uses the `csv-parse` npm package (RFC 4180-compliant: handles escaped
// `""` quotes and quoted fields containing literal newlines, which an
// earlier hand-rolled parser here did not) instead of a homegrown parser --
// run `npm install` in this `scripts/` folder once before use.
const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');

// Returns an array of row objects keyed by the CSV's own header row, e.g.
// { ID: '0', Directory: 'Azeroth', ... } -- same shape wow.export's DBC
// export produces, values always strings (callers parseInt/parseFloat as
// needed, matching every existing CSV column reference in this codebase).
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
