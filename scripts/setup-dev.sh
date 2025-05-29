#!/bin/bash
echo "🔧 FreezeMotions Development Setup"

if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js not found. Install from https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js $(node -v) found"
echo "📦 Installing dependencies..."

cd frontend && npm install && echo "✅ Frontend ready" && cd ..
cd backend && npm install && echo "✅ Backend ready" && cd ..

if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ .env created"
fi

echo "🎉 Setup complete!"
echo
echo "Start development:"
echo "  docker-compose up -d"
echo "  # OR native:"
echo "  cd frontend && npm start"
echo "  cd backend && npm run dev"
