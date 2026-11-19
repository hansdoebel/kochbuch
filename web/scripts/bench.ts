import { Catalog } from '../src/server/catalog';
const start = performance.now();
const catalog = new Catalog();
const startup = performance.now() - start;
const samples: number[] = [];
for (let n = 0; n < 250; n++) {
  const t = performance.now();
  catalog.search({ q: ['lentil', 'tofu', 'chicken', 'linsen', 'soup'][n % 5] });
  samples.push(performance.now() - t);
}
samples.sort((a, b) => a - b);
console.log(
  JSON.stringify(
    {
      recipes: catalog.meta().count,
      startup_ms: +startup.toFixed(2),
      search_median_ms: +samples[125].toFixed(2),
      search_p95_ms: +samples[237].toFixed(2),
      max_page: 30,
    },
    null,
    2
  )
);
catalog.close();
