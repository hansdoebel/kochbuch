import { resolve, sep } from 'node:path';
import { z } from 'zod';
import { Catalog } from './catalog';
import { shoppingList, selectionSchema, analyse } from './shopping';
import { typstSource, pdfExport, typstBinary } from './export';
const inputSchema = z.object({
  selections: selectionSchema,
  hidePantry: z.boolean().optional(),
  includeOptional: z.boolean().optional(),
});
export function createApp(catalog: Catalog, dist = resolve(import.meta.dir, '../../dist')) {
  return async function handle(req: Request): Promise<Response> {
    const url = new URL(req.url);
    try {
      if (url.pathname === '/api/meta' && req.method === 'GET')
        return Response.json({ ...catalog.meta(), pdfAvailable: !!typstBinary() });
      if (url.pathname === '/api/recipes' && req.method === 'GET') {
        if ((url.searchParams.get('q') ?? '').length > 200)
          return Response.json({ error: 'Suchanfrage zu lang.' }, { status: 400 });
        const offset = Number(url.searchParams.get('offset') ?? 0);
        if (!Number.isSafeInteger(offset) || offset < 0)
          return Response.json({ error: 'Ungültige Seite.' }, { status: 400 });
        return Response.json(
          catalog.search({
            q: url.searchParams.get('q') ?? '',
            source: url.searchParams.get('source') ?? '',
            ready: url.searchParams.get('ready') === 'true',
            offset,
            limit: 30,
          })
        );
      }
      if (url.pathname.startsWith('/api/recipes/') && req.method === 'GET') {
        const recipe = catalog.get(decodeURIComponent(url.pathname.slice('/api/recipes/'.length)));
        return recipe
          ? Response.json(recipe)
          : Response.json({ error: 'Rezept nicht gefunden.' }, { status: 404 });
      }
      if (
        ['/api/shopping', '/api/analysis', '/api/export'].includes(url.pathname) &&
        req.method === 'POST'
      ) {
        const origin = req.headers.get('origin');
        if (origin && origin !== url.origin)
          return Response.json(
            { error: 'Anfrage stammt von einer anderen Website.' },
            { status: 403 }
          );
        const raw = await req.text();
        if (raw.length > 16_384)
          return Response.json({ error: 'Auswahl zu groß.' }, { status: 413 });
        const input = inputSchema.parse(JSON.parse(raw));
        if (url.pathname === '/api/analysis')
          return Response.json(analyse(input.selections, (id) => catalog.get(id)));
        const list = shoppingList(input.selections, (id) => catalog.get(id), input);
        if (url.pathname === '/api/shopping') return Response.json(list);
        if (!list.recipes.length)
          return Response.json({ error: 'Bitte zuerst ein Rezept auswählen.' }, { status: 400 });
        const format = url.searchParams.get('format') ?? 'pdf';
        if (!['pdf', 'typ', 'json'].includes(format))
          return Response.json({ error: 'Unbekanntes Exportformat.' }, { status: 400 });
        const body =
          format === 'pdf'
            ? await pdfExport(list)
            : format === 'typ'
              ? typstSource(list)
              : JSON.stringify(list, null, 2);
        return new Response(body as BodyInit, {
          headers: {
            'Content-Type':
              format === 'pdf'
                ? 'application/pdf'
                : format === 'json'
                  ? 'application/json'
                  : 'text/plain; charset=utf-8',
            'Content-Disposition': `attachment; filename="einkaufsliste.${format}"`,
            'Cache-Control': 'no-store',
          },
        });
      }
      if (url.pathname.startsWith('/api/'))
        return Response.json({ error: 'API-Endpunkt nicht gefunden.' }, { status: 404 });
      if (req.method !== 'GET' && req.method !== 'HEAD')
        return new Response('Method not allowed', { status: 405 });
      const pathname = decodeURIComponent(url.pathname);
      const path = resolve(dist, '.' + pathname);
      if (!path.startsWith(dist + sep) && path !== dist)
        return new Response('Not found', { status: 404 });
      const file = Bun.file(path);
      if (await file.exists()) {
        const compressed = Bun.file(path + '.gz');
        if (
          pathname.startsWith('/assets/') &&
          req.headers.get('accept-encoding')?.includes('gzip') &&
          (await compressed.exists())
        )
          return new Response(compressed, {
            headers: {
              'Content-Type': file.type,
              'Content-Encoding': 'gzip',
              Vary: 'Accept-Encoding',
              'Cache-Control': 'public, max-age=31536000, immutable',
              'X-Content-Type-Options': 'nosniff',
            },
          });
        return new Response(file, {
          headers: {
            'Cache-Control': pathname.startsWith('/assets/')
              ? 'public, max-age=31536000, immutable'
              : 'no-cache',
            'X-Content-Type-Options': 'nosniff',
            Vary: 'Accept-Encoding',
          },
        });
      }
      if (pathname !== '/' && pathname.includes('.'))
        return new Response('Not found', { status: 404 });
      const index = Bun.file(resolve(dist, 'index.html'));
      return (await index.exists())
        ? new Response(index, {
            headers: {
              'Cache-Control': 'no-cache',
              'Content-Security-Policy':
                "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'",
            },
          })
        : new Response('Frontend fehlt: zuerst bun run build im web-Verzeichnis ausführen.', {
            status: 503,
          });
    } catch (error) {
      if (error instanceof z.ZodError || error instanceof SyntaxError)
        return Response.json({ error: 'Die Auswahl oder Anfrage ist ungültig.' }, { status: 400 });
      const message = error instanceof Error ? error.message : 'Unbekannter Fehler';
      return Response.json({ error: message }, { status: 400 });
    }
  };
}
