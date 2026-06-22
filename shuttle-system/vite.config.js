import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  // Add this server block to lock the port
  server: {
    port: 3000,
    strictPort: true, // This forces Vite to fail if 3000 is taken, rather than shifting to 3001
  }
})