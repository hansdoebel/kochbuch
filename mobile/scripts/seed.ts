import { Catalog } from "../../web/src/server/catalog";
import { mobileSnapshot } from "../../web/src/server/mobile-snapshot";
import { mkdirSync, writeFileSync } from "node:fs";
import { gunzipSync } from "node:zlib";
const catalog = new Catalog(undefined, false);
try {
  mkdirSync("public", { recursive: true });
  writeFileSync(
    "public/catalog.json",
    gunzipSync(mobileSnapshot(catalog).gzip),
  );
} finally {
  catalog.close();
}
