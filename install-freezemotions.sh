#!/bin/bash

# ===========================================
# FreezeMotions One-Click Installation Script
# Vollständig korrigierte Version
# ===========================================

set -e

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Banner
banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                    FreezeMotions One-Click Installer          ║
║                   Professional Photo Platform                 ║
║                         Complete Setup                        ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Parameter oder Defaults
DOMAIN=${1:-"localhost"}
LETSENCRYPT_EMAIL=${2:-"admin@${DOMAIN}"}
GITHUB_REPO="https://github.com/lawrencetjia/freezemotions.git"
INSTALL_DIR="/opt/freezemotions"

# Interaktive Eingaben
collect_user_input() {
    if [[ "$DOMAIN" == "localhost" && -z "$3" ]]; then
        echo
        info "=== FreezeMotions Konfiguration ==="
        read -p "🌐 Ihre Domain (z.B. meine-fotos.de, oder Enter für localhost): " INPUT_DOMAIN
        DOMAIN=${INPUT_DOMAIN:-localhost}
        
        if [[ "$DOMAIN" != "localhost" ]]; then
            read -p "📧 E-Mail für SSL-Zertifikate: " INPUT_EMAIL
            LETSENCRYPT_EMAIL=${INPUT_EMAIL:-admin@$DOMAIN}
            
            read -p "📮 SMTP-Host (optional, Enter zum Überspringen): " SMTP_HOST
            if [[ -n "$SMTP_HOST" ]]; then
                read -p "👤 SMTP-Benutzer: " SMTP_USER
                read -s -p "🔑 SMTP-Passwort: " SMTP_PASS
                echo
            fi
        fi
    fi
}

# System-Check
check_system() {
    log "Prüfe Systemvoraussetzungen..."
    
    # Root-Check
    if [[ $EUID -ne 0 ]]; then
        error "Dieses Script muss als root ausgeführt werden: sudo $0"
    fi
    
    # Ubuntu/Debian Check
    if ! command -v apt &> /dev/null; then
        error "Nur Ubuntu/Debian unterstützt (apt Package Manager erforderlich)"
    fi
    
    # RAM Check
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_ram -lt 1800 ]]; then
        warn "Weniger als 2GB RAM erkannt ($total_ram MB). Performance könnte beeinträchtigt sein."
    fi
    
    log "✅ System-Check erfolgreich"
}

# Dependencies installieren
install_dependencies() {
    log "Installiere System-Dependencies..."
    
    export DEBIAN_FRONTEND=noninteractive
    apt update
    apt upgrade -y
    
    # Docker installieren
    if ! command -v docker &> /dev/null; then
        log "Installiere Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        sleep 5
        log "✅ Docker installiert"
    else
        log "✅ Docker bereits vorhanden"
    fi
    
    # Docker Compose installieren
    if ! command -v docker-compose &> /dev/null; then
        log "Installiere Docker Compose..."
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4 2>/dev/null || echo "v2.20.0")
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log "✅ Docker Compose installiert"
    else
        log "✅ Docker Compose bereits vorhanden"
    fi
    
    # Weitere Tools
    apt install -y git nginx certbot python3-certbot-nginx curl wget jq
    
    log "✅ Dependencies installiert"
}

# Firewall konfigurieren (mit Fehlerbehandlung)
setup_firewall() {
    log "Konfiguriere Firewall..."
    
    # Warten falls iptables busy
    local max_attempts=5
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if ufw --force enable 2>/dev/null; then
            break
        else
            warn "Firewall-Lock erkannt, warte 10 Sekunden... ($attempt/$max_attempts)"
            sleep 10
            ((attempt++))
        fi
    done
    
    # Basis-Regeln
    ufw default deny incoming 2>/dev/null || true
    ufw default allow outgoing 2>/dev/null || true
    
    # Ports öffnen
    ufw allow ssh 2>/dev/null || true
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
    ufw allow 21/tcp 2>/dev/null || true
    ufw allow 21100:21110/tcp 2>/dev/null || true
    
    log "✅ Firewall konfiguriert"
}

# Repository klonen
clone_repository() {
    log "Klone FreezeMotions Repository..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log "Sichere bestehendes Verzeichnis..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
    
    git clone "$GITHUB_REPO" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    log "✅ Repository geklont"
}

# Umgebung konfigurieren
setup_environment() {
    log "Erstelle Konfiguration..."
    
    # Sichere Passwörter generieren
    DB_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    DB_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    JWT_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    FTP_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    MATOMO_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    
    # .env-Datei erstellen
    cat > .env << EOF
# FreezeMotions Production Configuration
# Generated: $(date)

DOMAIN=$DOMAIN
ANALYTICS_DOMAIN=analytics.$DOMAIN
FRONTEND_PORT=3000
BACKEND_PORT=3001

NODE_ENV=production

# Database
DB_HOST=mysql
DB_PORT=3306
DB_NAME=freezemotions
DB_USER=freezemotions
DB_PASSWORD=$DB_PASSWORD
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD

# FTP
FTP_USER=photographer
FTP_PASS=$FTP_PASS
FTP_PORT=21

# Matomo
MATOMO_URL=http://localhost:8081
MATOMO_SITE_ID=1
MATOMO_DB_PASSWORD=$MATOMO_PASS
MATOMO_DB_ROOT_PASSWORD=$MATOMO_PASS

# Security
JWT_SECRET=$JWT_SECRET
SESSION_SECRET=$JWT_SECRET
BCRYPT_ROUNDS=12

# Application
LOG_LEVEL=info
MAX_FILE_SIZE=50MB
ALLOWED_FILE_TYPES=jpg,jpeg,png,gif,webp,raw,cr2,nef,arw

# SSL
LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL
CERTBOT_STAGING=false

# SMTP
SMTP_HOST=${SMTP_HOST:-}
SMTP_PORT=587
SMTP_USER=${SMTP_USER:-}
SMTP_PASS=${SMTP_PASS:-}
SMTP_FROM=${SMTP_USER:-noreply@$DOMAIN}
EOF
    
    # Korrigierte docker-compose.yml erstellen
    cat > docker-compose.yml << 'EOF'
version: '3.3'

services:
  frontend:
    build: ./frontend
    container_name: freezemotions_frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:3001
      - REACT_APP_MATOMO_URL=http://localhost:8081
      - REACT_APP_MATOMO_SITE_ID=1
    depends_on:
      - backend
    restart: unless-stopped

  backend:
    build: ./backend
    container_name: freezemotions_backend
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_NAME=${DB_NAME:-freezemotions}
      - DB_USER=${DB_USER:-freezemotions}
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - mysql
      - redis
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    container_name: freezemotions_mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DB_NAME:-freezemotions}
      - MYSQL_USER=${DB_USER:-freezemotions}
      - MYSQL_PASSWORD=${DB_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "3306:3306"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: freezemotions_redis
    restart: unless-stopped

  ftp:
    image: fauria/vsftpd
    container_name: freezemotions_ftp
    environment:
      - FTP_USER=${FTP_USER:-photographer}
      - FTP_PASS=${FTP_PASS}
      - PASV_ADDRESS=${DOMAIN:-localhost}
      - PASV_MIN_PORT=21100
      - PASV_MAX_PORT=21110
    ports:
      - "21:21"
      - "21100-21110:21100-21110"
    restart: unless-stopped

  matomo:
    image: matomo:4
    container_name: freezemotions_matomo
    environment:
      - MATOMO_DATABASE_HOST=matomo-db
      - MATOMO_DATABASE_ADAPTER=mysql
      - MATOMO_DATABASE_TABLES_PREFIX=matomo_
      - MATOMO_DATABASE_USERNAME=matomo
      - MATOMO_DATABASE_PASSWORD=${MATOMO_DB_PASSWORD}
      - MATOMO_DATABASE_DBNAME=matomo
    ports:
      - "8081:80"
    depends_on:
      - matomo-db
    restart: unless-stopped

  matomo-db:
    image: mariadb:10
    container_name: freezemotions_matomo_db
    environment:
      - MYSQL_ROOT_PASSWORD=${MATOMO_DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=matomo
      - MYSQL_USER=matomo
      - MYSQL_PASSWORD=${MATOMO_DB_PASSWORD}
    restart: unless-stopped

volumes:
  mysql_data:
EOF
    
    # Storage-Verzeichnisse erstellen
    mkdir -p storage/{ftp,uploads,backups}
    mkdir -p backend/uploads
    mkdir -p logs
    
    # Berechtigungen setzen
    chown -R 1000:1000 storage backend/uploads logs 2>/dev/null || true
    
    log "✅ Konfiguration erstellt"
}

# Docker Container starten
start_containers() {
    log "Starte Docker Container..."
    log "Das kann 5-10 Minuten dauern..."
    
    # Container bauen und starten
    docker-compose up -d --build
    
    # Warten auf Services
    log "Warte auf Services (90 Sekunden)..."
    sleep 90
    
    # Frontend Build-Fix
    log "Repariere Frontend-Build..."
    docker-compose exec frontend sh -c "cd /app && npm install && npm run build" || true
    docker-compose restart frontend
    
    # Warten nach Frontend-Fix
    sleep 30
    
    # Container-Status prüfen
    log "Prüfe Container-Status..."
    docker-compose ps
    
    log "✅ Container gestartet"
}

# Nginx konfigurieren
setup_nginx() {
    log "Konfiguriere Nginx..."
    
    # Nginx-Konfiguration erstellen
    cat > /etc/nginx/sites-available/freezemotions << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:3001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        client_max_body_size 100M;
        proxy_request_buffering off;
    }
    
    location /health {
        proxy_pass http://127.0.0.1:3001/health;
        access_log off;
    }
}

server {
    listen 80;
    server_name analytics.$DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Site aktivieren
    ln -sf /etc/nginx/sites-available/freezemotions /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Nginx testen und starten
    if nginx -t; then
        systemctl enable nginx
        systemctl restart nginx
        log "✅ Nginx konfiguriert"
    else
        warn "Nginx-Konfiguration fehlerhaft"
    fi
}

# SSL-Zertifikate einrichten
setup_ssl() {
    if [[ "$DOMAIN" != "localhost" ]]; then
        log "Erstelle SSL-Zertifikate..."
        
        # Warten bis Nginx läuft
        sleep 10
        
        # SSL-Zertifikate holen
        certbot --nginx \
            -d $DOMAIN \
            -d www.$DOMAIN \
            -d analytics.$DOMAIN \
            --email $LETSENCRYPT_EMAIL \
            --agree-tos \
            --non-interactive \
            --redirect || warn "SSL-Setup fehlgeschlagen - prüfen Sie DNS-Einträge"
        
        # Auto-Renewal einrichten
        systemctl enable certbot.timer
        systemctl start certbot.timer
        
        log "✅ SSL konfiguriert"
    fi
}

# Health-Checks durchführen
run_health_checks() {
    log "Führe Health-Checks durch..."
    
    # Backend-Check
    for i in {1..10}; do
        if curl -f -s http://localhost:3001/health > /dev/null 2>&1; then
            log "✅ Backend Health Check: OK"
            break
        else
            log "Warte auf Backend... ($i/10)"
            sleep 10
        fi
    done
    
    # Frontend-Check
    for i in {1..5}; do
        if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
            log "✅ Frontend: OK"
            break
        else
            log "Warte auf Frontend... ($i/5)"
            sleep 10
        fi
    done
    
    # Domain-Check (falls konfiguriert)
    if [[ "$DOMAIN" != "localhost" ]]; then
        if curl -f -s http://$DOMAIN/health > /dev/null 2>&1; then
            log "✅ Domain-Zugriff: OK"
        else
            warn "Domain-Zugriff nicht verfügbar - prüfen Sie DNS-Einträge"
        fi
    fi
    
    log "✅ Health-Checks abgeschlossen"
}

# Auto-Start Service einrichten
setup_services() {
    log "Richte Auto-Start ein..."
    
    cat > /etc/systemd/system/freezemotions.service << EOF
[Unit]
Description=FreezeMotions Photo Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable freezemotions.service
    
    log "✅ Auto-Start konfiguriert"
}

# Erfolgs-Meldung
show_success() {
    echo
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}🎉 FreezeMotions erfolgreich installiert!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo
    echo -e "${BLUE}🌐 Verfügbare Services:${NC}"
    
    if [[ "$DOMAIN" == "localhost" ]]; then
        echo "   Frontend:     http://$(curl -s ifconfig.me 2>/dev/null || echo 'SERVER-IP'):3000"
        echo "   Backend API:  http://$(curl -s ifconfig.me 2>/dev/null || echo 'SERVER-IP'):3001/health"
        echo "   Analytics:    http://$(curl -s ifconfig.me 2>/dev/null || echo 'SERVER-IP'):8081"
    else
        echo "   Frontend:     https://$DOMAIN"
        echo "   Backend API:  https://$DOMAIN/health"
        echo "   Analytics:    https://analytics.$DOMAIN"
    fi
    
    echo "   MySQL:        localhost:3306"
    echo "   FTP Server:   ftp://$DOMAIN:21"
    echo
    echo -e "${BLUE}🔑 Zugangsdaten:${NC}"
    echo "   FTP Benutzer: photographer"
    echo "   FTP Passwort: $FTP_PASS"
    echo "   MySQL User:   freezemotions"
    echo "   MySQL Pass:   $DB_PASSWORD"
    echo
    echo -e "${BLUE}📁 Wichtige Pfade:${NC}"
    echo "   Installation: $INSTALL_DIR"
    echo "   Konfiguration: $INSTALL_DIR/.env"
    echo "   Uploads:      $INSTALL_DIR/storage"
    echo
    echo -e "${BLUE}🔧 Verwaltung:${NC}"
    echo "   Status:       cd $INSTALL_DIR && docker-compose ps"
    echo "   Logs:         cd $INSTALL_DIR && docker-compose logs [service]"
    echo "   Neustart:     cd $INSTALL_DIR && docker-compose restart"
    echo "   Stoppen:      cd $INSTALL_DIR && docker-compose down"
    echo
    echo -e "${BLUE}📊 Nächste Schritte:${NC}"
    echo "   1. Besuchen Sie die Website und registrieren Sie sich"
    echo "   2. Richten Sie Matomo Analytics ein"
    echo "   3. Testen Sie den FTP-Upload"
    echo "   4. Konfigurieren Sie E-Mail-Einstellungen (optional)"
    echo
    echo -e "${GREEN}Installation erfolgreich abgeschlossen! 🚀${NC}"
}

# Hauptfunktion
main() {
    banner
    collect_user_input "$@"
    check_system
    install_dependencies
    setup_firewall
    clone_repository
    setup_environment
    start_containers
    setup_nginx
    setup_ssl
    run_health_checks
    setup_services
    show_success
}

# Script ausführen
main "$@"
