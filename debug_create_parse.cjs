const fs = require('fs');
const text = fs.readFileSync('database/migrations/2024_01_01_000001_create_workforce_employee_table.php', 'utf8');
const createRE = /Schema::create\('([^']+)'[\s\S]*?function\s*\(Blueprint \$table\)\s*\{([\s\S]*?)\}\);/g;
const m = createRE.exec(text);
console.log('MATCH', !!m);
if (!m) process.exit(1);
console.log('TABLE', m[1]);
const body = m[2];
console.log('BODY START');
console.log(body);
console.log('BODY END');
const lines = body.split(/;\s*\n/);
console.log('SEGMENTS', lines.length);
const lineRe = /^\$table->([a-zA-Z0-9_]+)\(([^)]*)\)(.*);$/;
for (const s of lines) {
  const t = s.trim();
  if (!t) continue;
  const m2 = t.match(lineRe);
  console.log('SEG', JSON.stringify(t));
  console.log(' PARSE', m2 ? {method: m2[1], args: m2[2], rest: m2[3]} : 'NO MATCH');
}
