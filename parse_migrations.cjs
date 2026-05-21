const fs = require('fs');
const path = require('path');
const migrationsDir = path.join(process.cwd(), 'database', 'migrations');
const files = fs.readdirSync(migrationsDir).filter(f => f.endsWith('.php')).sort();
const migrate = {};
const parseLine = line => {
  const trimmed = line.trim();
  const colMatch = trimmed.match(/^\$table->([a-zA-Z0-9_]+)\(([^)]*)\)(.*)$/);
  if (!colMatch) return null;
  const method = colMatch[1];
  const args = colMatch[2];
  const rest = colMatch[3];
  const argList = args.split(',').map(a=>a.trim()).filter(Boolean);
  return {method, args:argList, rest};
};
const parseColumns = lines => {
  const cols=[];
  let foreigns=[];
  let indices=[];
  for (const raw of lines) {
    const line = raw.trim();
    if (!line.startsWith('$table->')) continue;
    const parsed = parseLine(line.replace(/\)\s*->\s*index\(\)/g, ') -> index()'));
    if (!parsed) continue;
    const {method,args,rest}=parsed;
    if (['id','bigIncrements','increments'].includes(method)) {
      cols.push({name:'id', type:'bigint', attrs:['primary','unsigned','autoincrement']});
      continue;
    }
    const scalarTypes = ['foreignId','unsignedBigInteger','unsignedInteger','integer','string','text','date','dateTime','timestamp','boolean','enum','decimal','float','longText','json','tinyInteger','char','binary','uuid','time','year','double','unsignedTinyInteger','unsignedMediumInteger','unsignedSmallInteger'];
    if (scalarTypes.includes(method)) {
      let name = args[0] ? args[0].replace(/['"`]/g,'') : null;
      if (!name && method==='foreignId' && args.length===0) continue;
      const attrs=[];
      if (rest.includes('->nullable()')) attrs.push('nullable');
      if (rest.includes('->unique()')) attrs.push('unique');
      if (rest.includes('->index()')) attrs.push('index');
      if (rest.includes('->default(')) {
        const m = rest.match(/->default\(([^)]+)\)/);
        if (m) attrs.push('default='+m[1].trim());
      }
      if (rest.includes('->unsigned()')) attrs.push('unsigned');
      if (rest.includes('->comment(')) attrs.push('comment');
      if (method==='foreignId' && !attrs.includes('unsigned')) attrs.push('unsigned');
      const type = method==='foreignId' ? 'unsignedBigInteger' : method;
      cols.push({name,type,attrs});
      continue;
    }
    if (method==='foreign') {
      const name = args[0].replace(/['"`]/g,'');
      const refMatch = line.match(/->references\('([^']+)'\)/);
      const onMatch  = line.match(/->on\('([^']+)'\)/);
      const delMatch = line.match(/->onDelete\('([^']+)'\)/);
      foreigns.push({column:name,references:refMatch?refMatch[1]:null,on:onMatch?onMatch[1]:null,onDelete:delMatch?delMatch[1]:null});
      continue;
    }
    if (method==='index' || method==='unique') {
      const cols = args.map(a=>a.replace(/['"\[\]\s]/g,'')).filter(Boolean);
      indices.push({columns:cols,type:method});
      continue;
    }
    if (method==='softDeletes') { cols.push({name:'deleted_at',type:'timestamp',attrs:['nullable']}); continue; }
    if (method==='timestamps') { cols.push({name:'created_at',type:'timestamp',attrs:['nullable']}); cols.push({name:'updated_at',type:'timestamp',attrs:['nullable']}); continue; }
  }
  return {cols,foreigns,indices};
};
for (const file of files) {
  const text = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
  const createRE = /Schema::create\('([^']+)'[\s\S]*?function\s*\(Blueprint \$table\)\s*\{([\s\S]*?)\}\);/g;
  const tableRE = /Schema::table\('([^']+)'[\s\S]*?function\s*\(Blueprint \$table\)\s*\{([\s\S]*?)\}\);/g;
  let m;
  while ((m=createRE.exec(text))) {
    const name = m[1];
    const body = m[2].split(/;\s*\n/);
    const result = parseColumns(body);
    if (!migrate[name]) migrate[name] = {file, columns:[], foreigns:[], indices:[], modifies:[]};
    migrate[name].createFrom = file;
    migrate[name].columns.push(...result.cols);
    migrate[name].foreigns.push(...result.foreigns);
    migrate[name].indices.push(...result.indices);
  }
  while ((m=tableRE.exec(text))) {
    const name = m[1];
    const body = m[2].split(/;\s*\n/);
    const result = parseColumns(body);
    if (!migrate[name]) migrate[name] = {file, columns:[], foreigns:[], indices:[], modifies:[]};
    migrate[name].modifies.push({file, cols:result.cols, foreigns:result.foreigns, indices:result.indices});
  }
}
const sql = fs.readFileSync('all_migrations.sql', 'utf8').split(/\r?\n/);
const actual = {tables:{}, altered:[]};
for (const line of sql) {
  const l = line.trim();
  if (!l.startsWith('â‡‚') && !l.startsWith('⇂')) continue;
  const cleanLine = l.replace(/^â‡‚|^⇂\s*/,'').trim();
  if (cleanLine.toLowerCase().startsWith('create table')) {
    const name = cleanLine.match(/^create table "([^"]+)"/i)?.[1];
    const colsPart = cleanLine.replace(/^create table "[^"]+" \(/i,'').replace(/\)$/, '');
    actual.tables[name] = {definition:cleanLine, raw:colsPart};
  } else if (cleanLine.toLowerCase().startsWith('alter table') || cleanLine.toLowerCase().startsWith('create index') || cleanLine.toLowerCase().startsWith('create unique index')) {
    actual.altered.push(cleanLine);
  }
}
const output = {migrations:Object.entries(migrate).map(([k,v])=>({table:k,file:v.file,columns:v.columns,foreigns:v.foreigns,indices:v.indices,modifies:v.modifies})), actual:{tables:Object.keys(actual.tables), altered:actual.altered}};
fs.writeFileSync('schema_parse_report.json', JSON.stringify(output,null,2));
console.log('WROTE schema_parse_report.json');
