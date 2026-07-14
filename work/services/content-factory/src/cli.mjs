import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { validateItem } from './policy.mjs';

const [, , command, file] = process.argv;
if (command !== 'validate' || !file) {
  console.error('Usage: node src/cli.mjs validate <content-item.json>');
  process.exit(2);
}
const item = JSON.parse(await readFile(resolve(file), 'utf8'));
const result = validateItem(item);
console.log(JSON.stringify(result, null, 2));
if (!result.valid) process.exit(1);
