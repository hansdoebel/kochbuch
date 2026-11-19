import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { existsSync } from 'node:fs';
import type { ShoppingList } from '../lib/types';
const template = await Bun.file(
  new URL('../../templates/shopping-list.typ', import.meta.url)
).text();
export function typstSource(list: ShoppingList) {
  const bytes = Array.from(new TextEncoder().encode(JSON.stringify(list)));
  return template.replace(
    '#let data = json("shopping-list.json")',
    `#let data = json(bytes((${bytes.join(',')},)))`
  );
}
export const typstBinary = () =>
  process.env.TYPST_BIN ||
  Bun.which('typst') ||
  (existsSync(
    resolve(import.meta.dir, '../../../.tools/typst/typst-x86_64-unknown-linux-musl/typst')
  )
    ? resolve(import.meta.dir, '../../../.tools/typst/typst-x86_64-unknown-linux-musl/typst')
    : null);
let activeCompilations = 0;
export async function pdfExport(list: ShoppingList): Promise<Uint8Array> {
  const binary = typstBinary();
  if (!binary)
    throw new Error(
      'Typst ist nicht installiert. Du kannst die .typ-Datei herunterladen oder TYPST_BIN setzen.'
    );
  if (activeCompilations >= 2)
    throw new Error('Es laufen bereits zwei Exporte. Bitte kurz warten.');
  activeCompilations++;
  let folder: string | undefined;
  try {
    folder = await mkdtemp(join(tmpdir(), 'kochbuch-export-'));
    await writeFile(join(folder, 'shopping-list.json'), JSON.stringify(list));
    await writeFile(join(folder, 'shopping-list.typ'), template);
    const child = Bun.spawn(
      [
        binary,
        'compile',
        '--root',
        folder,
        join(folder, 'shopping-list.typ'),
        join(folder, 'list.pdf'),
      ],
      { stdout: 'pipe', stderr: 'pipe', env: { ...process.env } }
    );
    const timer = setTimeout(() => child.kill(), 10_000);
    try {
      const stderrPromise = new Response(child.stderr).text();
      const code = await child.exited;
      const stderr = await stderrPromise;
      if (code !== 0) {
        console.error('Typst export:', stderr.slice(0, 1500));
        throw new Error(
          'PDF konnte nicht erstellt werden. Die Typst-Datei bleibt als Export verfügbar.'
        );
      }
      return new Uint8Array(await readFile(join(folder, 'list.pdf')));
    } finally {
      clearTimeout(timer);
    }
  } finally {
    try {
      if (folder) await rm(folder, { recursive: true, force: true });
    } finally {
      activeCompilations--;
    }
  }
}
