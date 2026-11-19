import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath, URL } from 'node:url';
export default defineConfig({
  plugins: [tailwindcss(), svelte()],
  resolve: { alias: { $lib: fileURLToPath(new URL('./src/lib', import.meta.url)) } },
  server: { proxy: { '/api': 'http://127.0.0.1:3000' } },
  build: { target: 'es2022', cssCodeSplit: true, chunkSizeWarningLimit: 250 },
});
