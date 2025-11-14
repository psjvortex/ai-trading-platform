import React from 'react'
import { createRoot } from 'react-dom/client'

function App() {
  return (
    <div style={{ color: '#e5e7eb', background: '#0b1220', minHeight: '100vh', padding: 16 }}>
      <h1>AI Trading Platform</h1>
      <p>Scaffold ready: Web + API + DB via docker-compose.</p>
    </div>
  )
}

createRoot(document.getElementById('root')!).render(<App />)
