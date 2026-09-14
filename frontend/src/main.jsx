import './index.css'

import App from './App.jsx'
import React from 'react'
import ReactDOM from 'react-dom/client'
import { initDatadogRum } from './datadog'

// Initialize Datadog RUM tracing
initDatadogRum();

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
