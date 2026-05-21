const { tables, indexes } = require('./sql_schema_parse.json');
console.log('tables', Object.keys(tables).length);
console.log('sample', Object.keys(tables).slice(0,20));
console.log('indexes', indexes.length);
console.log('firstTable', tables['workforce_employee'] ? tables['workforce_employee'].columns : 'missing');
