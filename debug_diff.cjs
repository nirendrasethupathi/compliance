const { migrations, actual } = require('./schema_parse_report.json');
const migTables = new Set(migrations.map(m => m.table));
const sqlTables = new Set(actual.tables);
const missing = [...migTables].filter(t => !sqlTables.has(t)).sort();
const extra = [...sqlTables].filter(t => !migTables.has(t)).sort();
console.log('missing', missing);
console.log('extra', extra);
console.log('commonCount', [...migTables].filter(t => sqlTables.has(t)).length);
console.log('migrationCount', migTables.size, 'sqlCount', sqlTables.size);
