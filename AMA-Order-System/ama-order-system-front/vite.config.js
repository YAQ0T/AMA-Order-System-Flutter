import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import fs from 'fs'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5174,
    https: {
      key: fs.readFileSync(path.resolve(__dirname, 'certs/server-key.pem')),
      cert: fs.readFileSync(path.resolve(__dirname, 'certs/server-cert.pem'))
      // Client certificate authentication disabled
      // ca: fs.readFileSync(path.resolve(__dirname, 'certs/ca-cert.pem')),
      // requestCert: true,
      // rejectUnauthorized: true
    },
    host: true
  }
})
