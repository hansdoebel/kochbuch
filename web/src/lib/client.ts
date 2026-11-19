export async function api<T>(path: string, body?: unknown, signal?: AbortSignal): Promise<T> {
  const response = await fetch(path, {
    method: body === undefined ? 'GET' : 'POST',
    headers: body === undefined ? undefined : { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal,
  });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error ?? 'Die Anfrage ist fehlgeschlagen.');
  return data;
}
export function readLocal<T>(key: string, fallback: T): T {
  try {
    return JSON.parse(localStorage.getItem('kochbuch:' + key) ?? 'null') ?? fallback;
  } catch {
    return fallback;
  }
}
export function writeLocal(key: string, value: unknown) {
  try {
    localStorage.setItem('kochbuch:' + key, JSON.stringify(value));
  } catch {
    /* Browser-private modes can disable storage. */
  }
}
export function localDate() {
  return new Date().toLocaleDateString('sv-SE');
}
