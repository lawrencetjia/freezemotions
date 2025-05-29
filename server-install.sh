#!/bin/bash

# ===========================================
# FreezeMotions Server Installation Script
# Für Ubuntu/Debian Server
# ===========================================

set -e

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[INSTALL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Banner
banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                    FreezeMotions Server Installation          ║
║                   Professional Photo Platform                 ║
║                         Server Setup                         ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
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
        read -p "Trotzdem fortfahren? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log "✅ System-Check erfolgreich"
}

# Benutzer-Eingaben sammeln
collect_user_input() {
    log "Sammle Konfigurationsdaten..."
    
    echo
    info "=== Domain-Konfiguration ==="
    read -p "🌐 Ihre Domain (z.B. meine-fotos.de): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        error "Domain ist erforderlich"
    fi
    
    read -p "📊 Analytics-Subdomain (Standard: analytics.$DOMAIN): " ANALYTICS_DOMAIN
    ANALYTICS_DOMAIN=${ANALYTICS_DOMAIN:-analytics.$DOMAIN}
    
    read -p "📧 E-Mail für SSL-Zertifikate: " LETSENCRYPT_EMAIL
    if [[ -z "$LETSENCRYPT_EMAIL" ]]; then
        error "E-Mail für Let's Encrypt ist erforderlich"
    fi
    
    echo
    info "=== SMTP-Konfiguration (optional) ==="
    read -p "📮 SMTP-Host (z.B. smtp.gmail.com, Enter für Überspringen): " SMTP_HOST
    if [[ -n "$SMTP_HOST" ]]; then
        read -p "👤 SMTP-Benutzer: " SMTP_USER
        read -s -p "🔑 SMTP-Passwort: " SMTP_PASS
        echo
    else
        warn "SMTP übersprungen - E-Mail-Funktionen nicht verfügbar"
    fi
    
    echo
    info "=== FTP-Konfiguration ==="
    read -p "📁 FTP-Benutzer (Standard: photographer): " FTP_USER
    FTP_USER=${FTP_USER:-photographer}
    
    read -s -p "🔑 FTP-Passwort: " FTP_PASS
    echo
    if [[ -z "$FTP_PASS" ]]; then
        FTP_PASS=$(openssl rand -base64 12)
        info "Auto-generiertes FTP-Passwort: $FTP_PASS"
    fi
    
    echo
    info "=== GitHub Repository ==="
    read -p "🐙 GitHub Repository URL (https://github.com/username/freezemotions.git): " GITHUB_REPO
    if [[ -z "$GITHUB_REPO" ]]; then
        GITHUB_REPO="https://github.com/yourusername/freezemotions.git"
        warn "Standard-Repository verwendet: $GITHUB_REPO"
    fi
    
    log "✅ Konfiguration vollständig"
}

# System-Dependencies installieren
install_dependencies() {
    log "Installiere System-Dependencies..."
    
    # System updaten
    apt update
    apt upgrade -y
    
    # Docker installieren
    if ! command -v docker &> /dev/null; then
        log "Installiere Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
        rm get-docker.sh
        log "✅ Docker installiert"
    else
        log "✅ Docker bereits installiert"
    fi
    
    # Docker Compose installieren
    if ! command -v docker-compose &> /dev/null; then
        log "Installiere Docker Compose..."
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log "✅ Docker Compose installiert"
    else
        log "✅ Docker Compose bereits installiert"
    fi
    
    # Weitere Tools
    apt install -y git nginx certbot python3-certbot-nginx ufw fail2ban htop curl wget jq
    
    log "✅ Dependencies installiert"
}

# Firewall konfigurieren
setup_firewall() {
    log "Konfiguriere Firewall..."
    
    # UFW aktivieren
    ufw --force enable
    
    # Standard-Regeln
    ufw default deny incoming
    ufw default allow outgoing
    
    # Erforderliche Ports öffnen
    ufw allow ssh
    ufw allow 80/tcp   # HTTP
    ufw allow 443/tcp  # HTTPS
    ufw allow 21/tcp   # FTP
    ufw allow 21100:21110/tcp  # FTP Passive Ports
    
    # Fail2ban für SSH-Schutz
    systemctl enable fail2ban
    systemctl start fail2ban
    
    log "✅ Firewall konfiguriert"
}

# FreezeMotions Repository klonen
clone_repository() {
    log "Klone FreezeMotions Repository..."
    
    # Arbeitsverzeichnis
    INSTALL_DIR="/opt/freezemotions"
    
    # Altes Verzeichnis entfernen falls vorhanden
    if [[ -d "$INSTALL_DIR" ]]; then
        warn "Bestehendes Verzeichnis gefunden, erstelle Backup..."
        mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Repository klonen
    git clone "$GITHUB_REPO" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    log "✅ Repository geklont nach $INSTALL_DIR"
}

# Umgebung konfigurieren
setup_environment() {
    log "Konfiguriere Umgebung..."
    
    # Sichere Passwörter generieren
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    DB_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 32)
    SESSION_SECRET=$(openssl rand -base64 32)
    MATOMO_DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # .env-Datei erstellen
    cat > .env << EOF
# ===========================================
# FreezeMotions Production Configuration
# Generated: $(date)
# ===========================================

# Domain & Ports
DOMAIN=$DOMAIN
ANALYTICS_DOMAIN=$ANALYTICS_DOMAIN
FRONTEND_PORT=3000
BACKEND_PORT=3001

# Environment
NODE_ENV=production

# Database Configuration
DB_HOST=mysql
DB_PORT=3306
DB_NAME=freezemotions
DB_USER=freezemotions
DB_PASSWORD=$DB_PASSWORD
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD

# SMTP Configuration
SMTP_HOST=$SMTP_HOST
SMTP_PORT=587
SMTP_USER=$SMTP_USER
SMTP_PASS=$SMTP_PASS
SMTP_FROM=${SMTP_USER:-noreply@$DOMAIN}
SMTP_SECURE=false

# FTP Configuration
FTP_USER=$FTP_USER
FTP_PASS=$FTP_PASS
FTP_PORT=21

# Matomo Analytics
MATOMO_URL=https://$ANALYTICS_DOMAIN
MATOMO_SITE_ID=1
MATOMO_DB_PASSWORD=$MATOMO_DB_PASSWORD
MATOMO_DB_ROOT_PASSWORD=$MATOMO_DB_PASSWORD

# Storage Configuration
STORAGE_PATH=./storage

# Security & Authentication
JWT_SECRET=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET
BCRYPT_ROUNDS=12

# Application Settings
LOG_LEVEL=info
MAX_FILE_SIZE=50MB
ALLOWED_FILE_TYPES=jpg,jpeg,png,gif,webp,raw,cr2,nef,arw

# SSL/TLS Settings
LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL
CERTBOT_STAGING=false

# Rate Limiting
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
EOF

    # Storage-Verzeichnisse erstellen
    mkdir -p storage/{ftp,uploads,backups}
    mkdir -p backend/uploads
    mkdir -p logs
    
    # Berechtigungen setzen
    chown -R 1000:1000 storage backend/uploads logs
    
    log "✅ Umgebung konfiguriert"
}

# Docker Container starten
start_containers() {
    log "Starte Docker Container..."
    
    # Container bauen und starten
    docker-compose up -d --build
    
    # Warten auf Services
    log "Warte auf Services..."
    sleep 30
    
    # Container-Status prüfen
    if docker-compose ps | grep -q "Exit\|Restarting"; then
        warn "Einige Container haben Probleme:"
        docker-compose ps
        echo
        warn "Logs prüfen mit: docker-compose logs [service-name]"
        echo
        read -p "Trotzdem fortfahren? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log "✅ Alle Container erfolgreich gestartet"
    fi
}

# Nginx konfigurieren
setup_nginx() {
    log "Konfiguriere Nginx..."
    
    # Nginx-Konfiguration erstellen
    cat > /etc/nginx/sites-available/freezemotions << EOF
# FreezeMotions Nginx Configuration

# HTTP -> HTTPS Redirect
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN $ANALYTICS_DOMAIN;
    
    # Let's Encrypt Challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# Main Frontend & API
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration (managed by Certbot)
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # File Upload Settings
        client_max_body_size 100M;
        proxy_request_buffering off;
    }
    
    # Health Check
    location /health {
        proxy_pass http://localhost:3001/health;
        access_log off;
    }
}

# Matomo Analytics
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $ANALYTICS_DOMAIN;
    
    # SSL Configuration (managed by Certbot)
    
    location / {
        proxy_pass http://localhost:8080;
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
    
    # Nginx-Konfiguration testen
    nginx -t
    
    # Nginx starten
    systemctl enable nginx
    systemctl restart nginx
    
    log "✅ Nginx konfiguriert"
}

# SSL-Zertifikate erstellen
setup_ssl() {
    log "Erstelle SSL-Zertifikate..."
    
    # WWW-Verzeichnis für Challenge
    mkdir -p /var/www/html
    chown -R www-data:www-data /var/www/html
    
    # SSL-Zertifikate holen
    certbot --nginx \
        -d $DOMAIN \
        -d www.$DOMAIN \
        -d $ANALYTICS_DOMAIN \
        --email $LETSENCRYPT_EMAIL \
        --agree-tos \
        --non-interactive \
        --redirect
    
    # Auto-Renewal einrichten
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    log "✅ SSL-Zertifikate erstellt"
}

# System-Services einrichten
setup_services() {
    log "Richte System-Services ein..."
    
    # Systemd-Service für FreezeMotions
    cat > /etc/systemd/system/freezemotions.service << EOF
[Unit]
Description=FreezeMotions Photo Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/freezemotions
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    # Service aktivieren
    systemctl daemon-reload
    systemctl enable freezemotions.service
    
    # Backup-Cron-Job
    cat > /etc/cron.daily/freezemotions-backup << 'EOF'
#!/bin/bash
cd /opt/freezemotions
docker-compose exec -T mysql mysqldump -u root -p"$DB_ROOT_PASSWORD" freezemotions > storage/backups/db_$(date +%Y%m%d).sql
find storage/backups -name "db_*.sql" -mtime +7 -delete
EOF
    chmod +x /etc/cron.daily/freezemotions-backup
    
    log "✅ System-Services eingerichtet"
}

# Abschluss-Tests
run_final_tests() {
    log "Führe Abschluss-Tests durch..."
    
    # Service-Status prüfen
    log "Container-Status:"
    docker-compose ps
    
    echo
    
    # HTTP-Tests
    log "Teste HTTP-Endpoints..."
    
    # Backend Health Check
    if curl -f -s http://localhost:3001/health > /dev/null; then
        log "✅ Backend Health Check: OK"
    else
        warn "❌ Backend Health Check fehlgeschlagen"
    fi
    
    # Frontend Check
    if curl -f -s http://localhost:3000 > /dev/null; then
        log "✅ Frontend: OK"
    else
        warn "❌ Frontend nicht erreichbar"
    fi
    
    # HTTPS-Tests (falls SSL funktioniert)
    if curl -f -s https://$DOMAIN/health > /dev/null 2>&1; then
        log "✅ HTTPS: OK"
    else
        warn "❌ HTTPS noch nicht verfügbar (DNS-Propagation?)"
    fi
    
    log "✅ Tests abgeschlossen"
}

# Erfolgs-Meldung anzeigen
show_success() {
    echo
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}🎉 FreezeMotions erfolgreich installiert!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo
    echo -e "${BLUE}🌐 URLs:${NC}"
    echo -e "   Frontend:    https://$DOMAIN"
    echo -e "   API:         https://$DOMAIN/health"
    echo -e "   Analytics:   https://$ANALYTICS_DOMAIN"
    echo -e "   FTP:         ftp://$DOMAIN:21"
    echo
    echo -e "${BLUE}📋 FTP-Zugangsdaten:${NC}"
    echo -e "   Benutzer:    $FTP_USER"
    echo -e "   Passwort:    $FTP_PASS"
    echo -e "   Server:      $DOMAIN"
    echo -e "   Port:        21"
    echo
    echo -e "${YELLOW}🔧 Nächste Schritte:${NC}"
    
    if [[ -n "$SMTP_HOST" ]]; then
        echo "1. ✅ E-Mail ist konfiguriert"
    else
        echo "1. 📧 E-Mail konfigurieren (optional):"
        echo "   - .env bearbeiten: nano /opt/freezemotions/.env"
        echo "   - Container neu starten: cd /opt/freezemotions && docker-compose restart"
    fi
    
    echo "2. 📊 Matomo Analytics einrichten:"
    echo "   - Besuchen Sie: https://$ANALYTICS_DOMAIN"
    echo "   - Folgen Sie dem Setup-Wizard"
    echo "3. 👤 Ersten Benutzer registrieren"
    echo "4. 📁 FTP-Verbindung mit Kamera testen"
    echo
    echo -e "${BLUE}📁 Wichtige Pfade:${NC}"
    echo -e "   Installation:     /opt/freezemotions"
    echo -e "   Konfiguration:    /opt/freezemotions/.env"
    echo -e "   Logs:            docker-compose logs [service]"
    echo -e "   Backups:         /opt/freezemotions/storage/backups"
    echo
    echo -e "${GREEN}Installation abgeschlossen! 🚀${NC}"
}

# Hauptfunktion
main() {
    banner
    check_system
    collect_user_input
    install_dependencies
    setup_firewall
    clone_repository
    setup_environment
    start_containers
    setup_nginx
    setup_ssl
    setup_services
    run_final_tests
    show_success
}

# Script ausführen
main "$@"
