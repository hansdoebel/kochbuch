import { Catalog } from './catalog';
import { createApp } from './app';
const start = performance.now();
const catalog = new Catalog();
const server = Bun.serve({
  hostname: process.env.HOST ?? '127.0.0.1',
  port: Number(process.env.PORT ?? 3000),
  maxRequestBodySize: 16_384,
  fetch: createApp(catalog),
});
console.log(
  `Kochbuch: ${server.url} · ${catalog.meta().count} Rezepte · Index ${Math.round(performance.now() - start)} ms`
);
process.on('SIGTERM', () => {
  server.stop();
  catalog.close();
  process.exit(0);
});
