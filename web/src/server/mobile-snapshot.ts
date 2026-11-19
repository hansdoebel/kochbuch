import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';
import type { Catalog } from './catalog';
export function mobileSnapshot(catalog: Catalog) {
  const json = JSON.stringify({ version: 1, recipes: catalog.mobileRecipes() });
  return {
    etag: '"' + createHash('sha256').update(json).digest('hex') + '"',
    gzip: gzipSync(json),
  };
}
