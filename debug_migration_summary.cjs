const report = require('./schema_parse_report.json');
const tables = {};
for (const mig of report.migrations) {
  if (mig.table) tables[mig.table] = mig;
}
const tableNames = Object.keys(tables).sort();
console.log('migration tables', tableNames.length);
console.log('sample', tableNames.slice(0,20));
console.log('first', tables['workforce_employee'] ? tables['workforce_employee'].columns : 'missing');
