import { mkdir, writeFile, rm } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve, join } from 'node:path';
const version = '0.15.1';
const sha = 'a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c';
if (process.platform !== 'linux' || process.arch !== 'x64')
  throw new Error(
    'Install Typst from https://github.com/typst/typst/releases and set TYPST_BIN. This helper supports Linux x64.'
  );
const folder = resolve(import.meta.dir, '../../.tools/typst');
await mkdir(folder, { recursive: true });
const response = await fetch(
  `https://github.com/typst/typst/releases/download/v${version}/typst-x86_64-unknown-linux-musl.tar.xz`
);
if (!response.ok) throw new Error('Typst download failed: ' + response.status);
const bytes = new Uint8Array(await response.arrayBuffer());
if (createHash('sha256').update(bytes).digest('hex') !== sha)
  throw new Error('Typst checksum mismatch');
const archive = join(folder, 'typst.tar.xz');
try {
  await writeFile(archive, bytes);
  const child = Bun.spawn(['tar', '-xJf', archive, '-C', folder]);
  if ((await child.exited) !== 0) throw new Error('Typst extraction failed');
  console.log('Verified Typst ' + version + ' installed in ' + folder);
} finally {
  await rm(archive, { force: true });
}
