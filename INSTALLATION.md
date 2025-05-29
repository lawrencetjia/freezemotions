# FreezeMotions Installation Guide

## 🚀 Automatische Installation

### Schnell-Installation
```bash
curl -sSL https://raw.githubusercontent.com/lawrencetjia/freezemotions/main/install-freezemotions.sh | sudo bash
Manuelle Installation
bashgit clone https://github.com/lawrencetjia/freezemotions.git
cd freezemotions
chmod +x install-freezemotions.sh
sudo ./install-freezemotions.sh
📋 Voraussetzungen

Ubuntu 20.04+ oder Debian 11+
Mindestens 2GB RAM
Root-Zugriff
Domain mit DNS-Einträgen (für Produktion)

🌐 Nach der Installation

Frontend: https://ihre-domain.de
Backend: https://ihre-domain.de/health
Analytics: https://analytics.ihre-domain.de
FTP: ftp://ihre-domain.de:21

🛠️ Wartung
bashcd /opt/freezemotions
docker-compose ps          # Status
docker-compose logs        # Logs
docker-compose restart     # Neustart
📞 Support

GitHub Issues: https://github.com/lawrencetjia/freezemotions/issues
E-Mail: info@freezemotions.com
