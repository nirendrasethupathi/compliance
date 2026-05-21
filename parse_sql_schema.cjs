const fs = require('fs');
const sql = fs.readFileSync('all_migrations.sql', 'utf8').split(/\r?\n/);
const tables = {};
const indexes = [];
const foreigns = [];
for (const raw of sql) {
  const line = raw.trim();
  if (!line.startsWith('â‡‚') && !line.startsWith('⇂')) continue;
  const text = line.replace(/^â‡‚|^⇂\s*/,'').trim();
  if (text.toLowerCase().startsWith('create table')) {
    const m = text.match(/^create table "([^"]+)" \((.*)\)$/i);
    if (!m) continue;
    const name = m[1];
    const body = m[2];
    const parts = [];
    let depth = 0;
    let current = '';
    for (let i = 0; i < body.length; i++) {
      const ch = body[i];
      if (ch === '(') depth++;
      if (ch === ')') depth--;
      if (ch === ',' && depth === 0) {
        parts.push(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }
    if (current.trim()) parts.push(current.trim());
    tables[name] = {columns: [], foreigns: [], checks: [], raw: body};
    for (const part of parts) {
      if (part.toLowerCase().startsWith('foreign key')) {
        const fk = part.match(/foreign key\("([^"]+)"\) references "([^"]+)"\("([^"]+)"\)(?: on delete ([^ ]+))?/i);
        if (fk) tables[name].foreigns.push({column: fk[1], references: fk[3], on: fk[2], onDelete: fk[4] || null});
      } else if (part.toLowerCase().startsWith('check')) {
        tables[name].checks.push(part);
      } else if (part.toLowerCase().startsWith('primary key')) {
        tables[name].primaryKey = part;
      } else {
        const col = part.match(/^"([^"]+)"\s+([a-zA-Z0-9_]+)(.*)$/);
        if (col) {
          const colName = col[1];
          const type = col[2];
          const rest = col[3].trim();
          tables[name].columns.push({name: colName, type, rest});
        }
      }
    }
  } else if (text.toLowerCase().startsWith('create index') || text.toLowerCase().startsWith('create unique index')) {
    const idx = text.match(/create (unique )?index "([^"]+)" on "([^"]+)" \((.*)\)/i);
    if (idx) {
      indexes.push({table: idx[3], name: idx[2], unique: !!idx[1], columns: idx[4].split(',').map(c=>c.replace(/"/g,'').trim())});
    }
  }
}
fs.writeFileSync('sql_schema_parse.json', JSON.stringify({tables, indexes}, null, 2));
console.log('WROTE sql_schema_parse.json', Object.keys(tables).length, 'tables', indexes.length, 'indexes');
