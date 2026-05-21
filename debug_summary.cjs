const { migrations, actual } = require('./schema_parse_report.json');
console.log('migrations', migrations.length);
console.log('actualTables', actual.tables.length);
console.log('sample', JSON.stringify(migrations.slice(0,10).map(m => ({ table: m.table, cols: m.columns.length, foreigns: m.foreigns.length, indices: m.indices.length, modifies: m.modifies.length })), null, 2));
console.log('actualSample', JSON.stringify(actual.tables.slice(0,20), null, 2));
