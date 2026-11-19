import { fileURLToPath } from 'node:url';
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { gzipSync } from 'node:zlib';
import { join } from 'node:path';
const directory = fileURLToPath(new URL('../dist/assets/', import.meta.url));
for (const name of await readdir(directory))
  if (/\.(js|css)$/.test(name))
    await writeFile(
      join(directory, name + '.gz'),
      gzipSync(await readFile(join(directory, name)), { level: 9 })
    );
