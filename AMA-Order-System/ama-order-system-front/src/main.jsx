import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

// Global error handler for debugging Safari issues
window.addEventListener('error', (event) => {
  console.error('Global error caught:', event.error);
  alert(`Error: ${event.error?.message || 'Unknown error'}`);
});

window.addEventListener('unhandledrejection', (event) => {
  console.error('Unhandled promise rejection:', event.reason);
  alert(`Promise rejection: ${event.reason}`);
});

console.log('Starting app initialization...');
console.log('Environment:', import.meta.env);

try {
  const rootElement = document.getElementById('root');
  console.log('Root element found:', rootElement);

  if (!rootElement) {
    throw new Error('Root element not found!');
  }

  createRoot(rootElement).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );

  console.log('App rendered successfully');
} catch (error) {
  console.error('Failed to render app:', error);
  alert(`Failed to render app: ${error.message}`);
  // Show error on screen
  document.body.innerHTML = `
    <div style="color: white; padding: 20px; font-family: monospace;">
      <h1>Error Loading App</h1>
      <p>${error.message}</p>
      <pre>${error.stack}</pre>
    </div>
  `;
}

// Service Worker registration with better error handling
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(registration => {
        console.log('SW registered: ', registration);
      })
      .catch(registrationError => {
        console.log('SW registration failed: ', registrationError);
        // Don't block app if SW fails
      });
  });
} else {
  console.log('Service Worker not supported in this browser');
}
