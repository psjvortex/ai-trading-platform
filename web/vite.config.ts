import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import * as fs from 'fs'
import * as path from 'path'
import { homedir } from 'os'

// Default location for source CSV files
const DEFAULT_CSV_FOLDER = path.join(homedir(), 'Desktop', 'MT5_Backtest_Files')

export default defineConfig({
  plugins: [
    react(),
    {
      name: 'csv-file-api',
      configureServer(server) {
        // API endpoint to list available CSV files
        server.middlewares.use('/api/csv-files', (req, res, next) => {
          if (req.method !== 'GET') return next()
          
          try {
            const files = fs.readdirSync(DEFAULT_CSV_FOLDER)
              .filter(f => f.endsWith('.csv'))
            
            // Categorize files
            const mt5Report = files.find(f => f.includes('MT5Report') || f.includes('Report'))
            const eaTrades = files.find(f => f.includes('MASTER_trades') || (f.includes('_trades') && !f.includes('Report') && !f.includes('signals')))
            const eaSignals = files.find(f => f.includes('_signals'))
            
            res.setHeader('Content-Type', 'application/json')
            res.end(JSON.stringify({
              folder: DEFAULT_CSV_FOLDER,
              files: {
                mt5Report: mt5Report || null,
                eaTrades: eaTrades || null,
                eaSignals: eaSignals || null
              },
              allFiles: files
            }))
          } catch (err) {
            res.statusCode = 500
            res.end(JSON.stringify({ error: String(err) }))
          }
        })
        
        // API endpoint to read a specific CSV file
        server.middlewares.use('/api/csv-content', (req, res, next) => {
          if (req.method !== 'GET') return next()
          
          const url = new URL(req.url!, `http://${req.headers.host}`)
          const filename = url.searchParams.get('file')
          
          if (!filename) {
            res.statusCode = 400
            res.end(JSON.stringify({ error: 'Missing file parameter' }))
            return
          }
          
          // Security: only allow files from the designated folder
          const filePath = path.join(DEFAULT_CSV_FOLDER, path.basename(filename))
          
          try {
            if (!fs.existsSync(filePath)) {
              res.statusCode = 404
              res.end(JSON.stringify({ error: 'File not found' }))
              return
            }
            
            const content = fs.readFileSync(filePath, 'utf-8')
            res.setHeader('Content-Type', 'text/csv')
            res.end(content)
          } catch (err) {
            res.statusCode = 500
            res.end(JSON.stringify({ error: String(err) }))
          }
        })
      }
    }
  ],
  server: { host: true, port: 5173 }
})
