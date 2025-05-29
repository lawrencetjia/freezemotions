const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.BACKEND_PORT || 3001;

app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        service: 'FreezeMotions API'
    });
});

// API info
app.get('/api', (req, res) => {
    res.json({
        name: 'FreezeMotions API',
        version: '1.0.0',
        endpoints: ['/health', '/api']
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 FreezeMotions Backend running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
});
