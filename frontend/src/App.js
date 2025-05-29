import React, { useState, useEffect } from 'react';

function App() {
  const [status, setStatus] = useState('Checking...');

  useEffect(() => {
    fetch('/api/health')
      .then(res => res.json())
      .then(data => setStatus(data.status))
      .catch(() => setStatus('Backend not available'));
  }, []);

  return (
    <div style={{ padding: '20px', textAlign: 'center' }}>
      <h1>🚀 FreezeMotions React App</h1>
      <p>Backend Status: <strong>{status}</strong></p>
      <p>Die Haupt-UI wird über die statische HTML-Seite angezeigt.</p>
    </div>
  );
}

export default App;
