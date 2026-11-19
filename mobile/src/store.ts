import { CapacitorHttp } from "@capacitor/core";
import type { Recipe } from "../../web/src/lib/types";
export function read<T>(key: string, fallback: T): T {
  try {
    return (
      JSON.parse(localStorage.getItem("mobile:" + key) ?? "null") ?? fallback
    );
  } catch {
    return fallback;
  }
}
export function save(key: string, value: unknown) {
  localStorage.setItem("mobile:" + key, JSON.stringify(value));
}
function validate(data: any): Recipe[] {
  if (
    data?.version !== 1 ||
    !Array.isArray(data.recipes) ||
    !data.recipes.length ||
    data.recipes.some(
      (r: any) =>
        !r ||
        typeof r.id !== "string" ||
        typeof r.title !== "string" ||
        !Array.isArray(r.ingredients) ||
        !Array.isArray(r.instructions) ||
        !Array.isArray(r.tags) ||
        !Array.isArray(r.structuredIngredients),
    )
  )
    throw Error("Ungültiger Rezeptkatalog.");
  if (
    new Set(data.recipes.map((r: Recipe) => r.id)).size !== data.recipes.length
  )
    throw Error("Doppelte Rezept-ID.");
  return data.recipes;
}
type Snapshot = {
  version: 1;
  recipes: Recipe[];
  etag: string;
  url: string;
  updated: string;
};
async function database() {
  return new Promise<IDBDatabase>((resolve, reject) => {
    const req = indexedDB.open("kochbuch-katalog", 1);
    req.onupgradeneeded = () => req.result.createObjectStore("catalog");
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}
export async function current(): Promise<Snapshot> {
  const db = await database();
  try {
    const stored = await new Promise<Snapshot | undefined>(
      (resolve, reject) => {
        const r = db
          .transaction("catalog")
          .objectStore("catalog")
          .get("current");
        r.onsuccess = () => resolve(r.result);
        r.onerror = () => reject(r.error);
      },
    );
    if (stored) {
      validate(stored);
      return stored;
    }
  } finally {
    db.close();
  }
  const data = await (await fetch("/catalog.json")).json();
  return {
    version: 1,
    recipes: validate(data),
    etag: "",
    url: "",
    updated: "",
  };
}
export async function sync(origin: string, old: Snapshot): Promise<Snapshot> {
  const url = new URL(origin);
  if (
    url.protocol !== "https:" ||
    url.username ||
    url.password ||
    url.search ||
    url.hash
  )
    throw Error("HTTPS-Adresse deines Kochbuch-Servers eingeben.");
  const endpoint = url.href.replace(/\/$/, "") + "/api/mobile/catalog";
  const response = await CapacitorHttp.get({
    url: endpoint,
    headers:
      old.etag && old.url === endpoint ? { "If-None-Match": old.etag } : {},
    connectTimeout: 15000,
    readTimeout: 60000,
  });
  if (response.status === 304) return old;
  if (response.status !== 200)
    throw Error("Server meldet HTTP " + response.status);
  const data =
    typeof response.data === "string"
      ? JSON.parse(response.data)
      : response.data;
  const next: Snapshot = {
    version: 1,
    recipes: validate(data),
    etag:
      Object.entries(response.headers).find(
        ([k]) => k.toLowerCase() === "etag",
      )?.[1] ?? "",
    url: endpoint,
    updated: new Date().toISOString(),
  };
  const db = await database();
  try {
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction("catalog", "readwrite");
      tx.oncomplete = () => resolve();
      tx.onabort = () => reject(tx.error);
      tx.objectStore("catalog").put(next, "current");
    });
  } finally {
    db.close();
  }
  return next;
}
