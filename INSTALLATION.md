# FreezeMotions Installation Guide

## 🚀 Schnell-Installation (Empfohlen)

```bash
# Direkt auf Ubuntu/Debian-Server:
curl -sSL https://raw.githubusercontent.com/lawrencetjia/freezemotions/main/server-install.sh | sudo bash

📋 Manuelle Installation
1. Repository klonen
bashgit clone https://github.com/lawrencetjia/freezemotions.git
cd freezemotions
2. Server-Installation starten
bashchmod +x server-install.sh
sudo ./server-install.sh
3. DNS-Einträge setzen (VORHER!)
A-Record: ihre-domain.de → Server-IP
A-Record: www.ihre-domain.de → Server-IP  
A-Record: analytics.ihre-domain.de → Server-IP
🔧 Lokale Entwicklung
bash# Dependencies installieren
./scripts/setup-dev.sh

# Mit Docker
docker-compose up -d

# Services verfügbar unter:
# - Frontend: http://localhost:3000
# - Backend: http://localhost:3001
# - Matomo: http://localhost:8080
📞 Support
Bei Problemen:

Logs prüfen: docker-compose logs [service]
GitHub Issues: https://github.com/lawrencetjia/freezemotions/issues
E-Mail: support@freezemotions.com
