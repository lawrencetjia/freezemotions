<<<<<<< HEAD
# freezemotions
Professional Self-Hosted Photo Platform - GDPR compliant Flickr 
=======
# FreezeMotions

Professional Self-Hosted Photo Platform

## 🚀 Quick Start

```bash
# Development
docker-compose up -d

# Services:
# Frontend:  http://localhost:3000
# Backend:   http://localhost:3001
# Matomo:    http://localhost:8080
# MySQL:     localhost:3306
```

## ⚙️ Configuration

1. Copy `.env.example` to `.env`
2. Edit values as needed
3. Run `docker-compose up -d`

## 📞 Support

- GitHub: https://github.com/username/freezemotions
- Email: info@freezemotions.com


## 🚀 Server-Installation

Für die Produktions-Installation auf einem Ubuntu/Debian-Server:

```bash
# Direkte Installation vom GitHub-Repository
curl -sSL https://raw.githubusercontent.com/lawrencetjia/freezemotions/main/server-install.sh | sudo bash

# ODER manuell:
git clone https://github.com/lawrencetjia/freezemotions.git
cd freezemotions
chmod +x server-install.sh
sudo ./server-install.sh
Voraussetzungen für Server-Installation:

Ubuntu 20.04+ oder Debian 11+
Root-Zugriff (sudo)
Mindestens 2GB RAM
Domain mit DNS-Einträgen auf Server-IP

DNS-Einträge setzen:
A-Record: ihre-domain.de → Server-IP
A-Record: www.ihre-domain.de → Server-IP
A-Record: analytics.ihre-domain.de → Server-IP
📊 Nach der Installation verfügbar:

Frontend: https://ihre-domain.de
Backend API: https://ihre-domain.de/health
Matomo Analytics: https://analytics.ihre-domain.de
FTP-Server: ftp://ihre-domain.de:21

🔧 Wartung
bash# Container-Status prüfen
cd /opt/freezemotions
docker-compose ps

# Logs ansehen
docker-compose logs [service-name]

# Container neu starten
docker-compose restart

# System-Update
git pull origin main
docker-compose up -d --build
>>>>>>> ac98264 (🎉 Complete FreezeMotions Platform)
## 🚀 One-Click Installation (Neu!)

**Vollautomatische Installation auf Ubuntu/Debian-Server:**

```bash
# Ein-Befehl-Installation
curl -sSL https://raw.githubusercontent.com/lawrencetjia/freezemotions/main/install-freezemotions.sh | sudo bash
Das Script macht automatisch:

✅ System-Check und Dependencies
✅ Docker + Docker Compose Installation
✅ Firewall-Konfiguration
✅ SSL-Zertifikate mit Let's Encrypt
✅ Nginx Reverse Proxy Setup
✅ Alle Container starten und konfigurieren
✅ Health-Checks durchführen
✅ Auto-Start Services einrichten

Nach der Installation verfügbar:

Frontend: https://ihre-domain.de
Backend: https://ihre-domain.de/health
Analytics: https://analytics.ihre-domain.de
FTP: ftp://ihre-domain.de:21

Lokale Entwicklung:
bashgit clone https://github.com/lawrencetjia/freezemotions.git
cd freezemotions
docker-compose up -d
# Services: http://localhost:3000, :3001, :8081

v2.0 Updates:

🔧 Docker-Compose Kompatibilität behoben
🎨 Frontend-Build-Probleme gelöst
🛡️ Robuste Firewall-Konfiguration
🔒 Automatisches SSL-Setup
📊 Erweiterte Health-Checks
🚀 Production-ready Deployment
