const fs = require('fs');
const lineRegex = /^\$table->([a-zA-Z0-9_]+)\(([^)]*)\)(.*);$/;
const lines = [
  "$table->id();",
  "$table->unsignedBigInteger('tenant_id')->index();",
  "$table->decimal('basic_salary', 12, 2)->default(0);",
  "$table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');",
  "$table->string('description')->nullable()->comment('text');"
];
for (const line of lines) {
  const m = line.match(lineRegex);
  console.log('LINE>', line);
  console.log('MATCH>', !!m, m ? {method: m[1], args: m[2], rest: m[3]} : null);
}
