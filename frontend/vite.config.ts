import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api/auth': 'http://localhost:4001',
      '/api/catalog': 'http://localhost:4002',
      '/api/checkout': 'http://localhost:4003',
      '/api/payment': 'http://localhost:4004',
    },
  },
});
