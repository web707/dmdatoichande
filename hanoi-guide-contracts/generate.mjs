import { readFileSync, writeFileSync } from 'node:fs';

const spec = JSON.parse(readFileSync(new URL('./openapi/destinations-v1.json', import.meta.url), 'utf8'));
const check = process.argv.includes('--check');
const banner = '// Generated from openapi/destinations-v1.json. Do not edit.\n';

function modelType(schema, kotlin) {
  if (schema.$ref?.startsWith('#/components/schemas/')) return schema.$ref.split('/').at(-1);
  if (schema.type === 'string') return kotlin ? 'String' : 'string';
  if (schema.type === 'integer') return kotlin ? 'Int' : 'number';
  if (schema.type === 'number') return kotlin ? 'Double' : 'number';
  if (schema.type === 'array') {
    const item = modelType(schema.items, kotlin);
    return kotlin ? `List<${item}>` : `${item}[]`;
  }
  if (JSON.stringify(schema.type) === '["string","null"]') return kotlin ? 'String?' : 'string | null';
  throw new Error(`Unsupported destination model field: ${JSON.stringify(schema)}`);
}

const tsModels = [];
const kotlinModels = [];
for (const [name, schema] of Object.entries(spec.components.schemas)) {
  const fields = Object.entries(schema.properties);
  if (schema.type !== 'object' || fields.some(([field]) => !schema.required.includes(field))) {
    throw new Error(`Expected an object model with required properties: ${name}`);
  }
  tsModels.push(`export interface ${name} {\n${fields.map(([field, type]) => `  ${field}: ${modelType(type, false)};`).join('\n')}\n}`);
  kotlinModels.push(`@Serializable\ndata class ${name}(\n${fields.map(([field, type]) => `    val ${field}: ${modelType(type, true)},`).join('\n')}\n)`);
}

const outputs = {
  './generated-typescript/destinations.ts': `${banner}\n${tsModels.join('\n\n')}\n`,
  './generated-kotlin/Destinations.kt': `${banner}\npackage com.hanoiguide.contracts\n\nimport kotlinx.serialization.Serializable\n\n${kotlinModels.join('\n\n')}\n`,
};

for (const [path, content] of Object.entries(outputs)) {
  const output = new URL(path, import.meta.url);
  if (check) {
    const existing = readFileSync(output, 'utf8').replaceAll('\r\n', '\n');
    if (existing !== content) {
      console.error(`${path} is stale. Run node hanoi-guide-contracts/generate.mjs.`);
      process.exitCode = 1;
    }
  } else {
    writeFileSync(output, content);
  }
}
