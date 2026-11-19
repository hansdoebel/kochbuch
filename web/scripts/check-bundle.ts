import { fileURLToPath } from 'node:url';
import { readdir, stat } from 'node:fs/promises';
import { join } from 'node:path';
const directory = fileURLToPath(new URL('../dist/assets/', import.meta.url));
for (const name of await readdir(directory))
  if (name.endsWith('.gz')) {
    const size = (await stat(join(directory, name))).size;
    const limit = name.endsWith('.css.gz') ? 20_480 : 102_400;
    console.log(`${name}: ${(size / 1024).toFixed(1)} KiB / ${limit / 1024} KiB budget`);
    if (size > limit) throw new Error('Compressed bundle budget exceeded: ' + name);
  }
