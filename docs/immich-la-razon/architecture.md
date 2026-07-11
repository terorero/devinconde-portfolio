# Immich Media Platform - La Razón Implementation

**Cliente:** Comunicaciones El País (Periódico La Razón - Bolivia)  
**Fecha:** Julio 2025  
**Estado:** Producción  
**Infraestructura:** ThinkServer RD630 (RAID 5, 2TB) - Docker

---

## 🏗 Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                    ThinkServer RD630                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Docker Engine                            │ │
│  │  ┌──────────────────┐    ┌──────────────────────────────┐  │ │
│  │  │   Immich Stack   │    │    Sistema Contable Stack    │  │ │
│  │  │  ┌────────────┐  │    │  ┌────────────────────────┐  │  │ │
│  │  │  │  immich-   │  │    │  │  app-contaible/        │  │  │ │
│  │  │  │  server    │  │    │  │  nginx + php-fpm       │  │  │ │
│  │  │  ├────────────┤  │    │  ├────────────────────────┤  │  │ │
│  │  │  │  immich-   │  │    │  │  db-mariadb (separado) │  │  │ │
│  │  │  │  ml        │  │    │  └────────────────────────┘  │  │ │
│  │  │  ├────────────┤  │    │                              │  │ │
│  │  │  │  immich-   │  │    │  ┌────────────────────────┐  │  │ │
│  │  │  │  postgres  │  │    │  │  Red virtual aislada   │  │  │ │
│  │  │  ├────────────┤  │    │  │  (bridge + macvlan)    │  │  │ │
│  │  │  │  redis     │  │    │  └────────────────────────┘  │  │  │ │
│  │  │  └────────────┘  │    └──────────────────────────────┘  │  │ │
│  │  └──────────────────┘    ┌──────────────────────────────┐  │  │ │
│  │                          │  Volúmenes Compartidos       │  │  │ │
│  │                          │  /data/immich (RAID 5)        │  │  │ │
│  │                          │  /data/contable (RAID 5)      │  │  │ │
│  │                          │  /backup (Borg + Synology)    │  │  │ │
│  │                          └──────────────────────────────┘  │  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🐳 Docker Compose - Immich Stack

```yaml
# docker-compose.immich.yml
version: '3.8'

services:
  # Base de datos PostgreSQL con extensiones vectoriales
  immich-postgres:
    image: ghcr.io/immich-app/immich-postgres:latest
    container_name: immich-postgres
    environment:
      POSTGRES_DB: immich
      POSTGRES_USER: immich
      POSTGRES_PASSWORD: ${IMMICH_DB_PASSWORD}
      POSTGRES_INITDB_ARGS: '--data-checksums'
    volumes:
      - /data/immich/postgres:/var/lib/postgresql/data
    healthcheck:
      test: pg_isready -U immich -d immich
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - immich-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'

  # Redis para caché y sesiones
  immich-redis:
    image: redis:7-alpine
    container_name: immich-redis
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - /data/immich/redis:/data
    healthcheck:
      test: redis-cli ping
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - immich-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  # Servidor principal Immich
  immich-server:
    image: ghcr.io/immich-app/immich-server:latest
    container_name: immich-server
    environment:
      DB_HOSTNAME: immich-postgres
      DB_DATABASE_NAME: immich
      DB_USERNAME: immich
      DB_PASSWORD: ${IMMICH_DB_PASSWORD}
      REDIS_HOSTNAME: immich-redis
      UPLOAD_LOCATION: /usr/src/app/upload
      IMMICH_VERSION: ${IMMICH_VERSION:-release}
      MACHINE_LEARNING_ENABLED: 'true'
      LOG_LEVEL: info
      REVERSE_PROXY_PREFIX: ''
    volumes:
      - /data/immich/upload:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "2283:3001"
    depends_on:
      immich-postgres:
        condition: service_healthy
      immich-redis:
        condition: service_healthy
    networks:
      - immich-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
        reservations:
          memory: 2G
          cpus: '1.0'
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:3001/api/server-info/ping || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Machine Learning para IA (reconocimiento facial, objetos)
  immich-ml:
    image: ghcr.io/immich-app/immich-machine-learning:latest
    container_name: immich-ml
    environment:
      TRANSFORMERS_CACHE: /cache
    volumes:
      - /data/immich/ml-cache:/cache
    networks:
      - immich-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 3G
          cpus: '2.0'
        reservations:
          memory: 2G
          cpus: '1.0'
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:3003/ping || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

networks:
  immich-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16

volumes:
  postgres-data:
  redis-data:
```

---

## 📊 .env - Variables de Entorno

```bash
# /data/immich/.env
# Immich Configuration
IMMICH_VERSION=release
IMMICH_DB_PASSWORD=CHANGE_ME_SECURE_PASSWORD_256_BITS
IMMICH_JWT_SECRET=CHANGE_ME_JWT_SECRET_256_BITS

# Upload
UPLOAD_LOCATION=/usr/src/app/upload

# ML
MACHINE_LEARNING_ENABLED=true

# PostgreSQL
POSTGRES_DB=immich
POSTGRES_USER=immich
POSTGRES_PASSWORD=CHANGE_ME_SECURE_PASSWORD_256_BITS

# Backup
BORG_REPO=ssh://borg@backup-server:/volume1/borg-backups/la-razon-immich
BORG_PASSPHRASE=CHANGE_ME_BORG_PASSPHRASE
BORG_EXCLUDE=/data/immich/ml-cache
```

---

## 🔧 Configuración de Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/immich
server {
    listen 80;
    server_name immich.la-razon.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name immich.la-razon.com;

    ssl_certificate /etc/letsencrypt/live/immich.la-razon.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/immich.la-razon.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    client_max_body_size 500M;
    client_body_timeout 300s;

    location / {
        proxy_pass http://localhost:2283;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # WebSocket para notificaciones en tiempo real
    location /api/websocket {
        proxy_pass http://localhost:2283;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # Health check
    location /health {
        access_log off;
        proxy_pass http://localhost:2283/api/server-info/ping;
    }
}
```

---

## 💾 Backup Strategy - Borg + Synology

```bash
#!/bin/bash
# /opt/scripts/backup-immich.sh
# Ejecutado diariamente via cron (0 2 * * *)

set -euo pipefail

export BORG_REPO="ssh://borg@synology-dr:/volume1/borg-backups/la-razon-immich"
export BORG_PASSPHRASE="${BORG_PASSPHRASE}"
export BORG_EXCLUDE="/data/immich/ml-cache"

LOG="/var/log/borg-immich.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

log "=== INICIO BACKUP IMMICH ==="

# 1. Dump PostgreSQL
log "Dumping PostgreSQL..."
docker exec immich-postgres pg_dump -U immich immich | gzip > /tmp/immich-db-$(date +%F).sql.gz

# 2. Backup con Borg
log "Running borg create..."
borg create --verbose --stats --compression lz4 \
  --exclude-caches \
  --exclude '/data/immich/ml-cache' \
  --exclude '/data/immich/postgres/pg_wal' \
  "$BORG_REPO::immich-{hostname}-{now:%Y-%m-%dT%H:%M:%S}" \
  /data/immich/upload \
  /data/immich/postgres \
  /data/immich/redis \
  /tmp/immich-db-$(date +%F).sql.gz \
  2>&1 | tee -a "$LOG"

# 3. Prune (retención)
log "Pruning old backups..."
borg prune --list --stats \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --keep-yearly 3 \
  "$BORG_REPO" 2>&1 | tee -a "$LOG"

# 4. Verificación
log "Verifying backup integrity..."
borg check -v "$BORG_REPO" 2>&1 | tee -a "$LOG"

# 5. Cleanup
rm -f /tmp/immich-db-$(date +%F).sql.gz

log "=== BACKUP IMMICH COMPLETADO ==="
```

---

## 📈 Monitoreo - Prometheus Exporter

```yaml
# monitoring/rules/immich-alerts.yml
groups:
  - name: immich
    interval: 60s
    rules:
      - alert: ImmichDown
        expr: up{job="immich"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Immich service down"
          description: "Immich has been down for 2 minutes"

      - alert: ImmichHighMemory
        expr: (container_memory_usage_bytes{name=~"immich-.*"} / container_spec_memory_limit_bytes{name=~"immich-.*"}) * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Immich high memory usage"
          description: "{{ $labels.name }} memory at {{ $value }}%"

      - alert: ImmichDiskSpace
        expr: (node_filesystem_avail_bytes{mountpoint="/data/immich"} / node_filesystem_size_bytes{mountpoint="/data/immich"}) * 100 < 15
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Immich disk space critical"
          description: "Less than 15% free on /data/immich"

      - alert: ImmichBackupFailed
        expr: increase(borg_backup_exit_code[1h]) > 0
        labels:
          severity: critical
        annotations:
          summary: "Immich backup failed"
          description: "Borg backup exited with non-zero code"
```

---

## 🔐 Seguridad y Hardening

### Container Security
```yaml
# Adiciones a docker-compose.yml para seguridad
services:
  immich-server:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache
    user: "1000:1000"
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - SETGID
      - SETUID
```

### Firewall (nftables)
```bash
# Solo acceso vía nginx proxy
nft add rule inet filter input tcp dport 2283 ip saddr != 127.0.0.1 drop
```

---

## 📋 Checklist de Despliegue

| Paso | Acción | Comando/Verificación | ✓ |
|------|--------|---------------------|---|
| 1 | Preparar servidor RD630 | RAID 5 healthy, 2TB free | |
| 2 | Instalar Docker + Compose | `docker --version && docker compose version` | |
| 3 | Configurar .env | Passwords únicos, JWT secret | |
| 4 | Crear redes/volúmenes | `docker network create immich-network` | |
| 5 | Desplegar stack | `docker compose -f docker-compose.immich.yml up -d` | |
| 6 | Verificar healthchecks | `docker compose ps` (todos healthy) | |
| 7 | Configurar Nginx + SSL | `nginx -t && systemctl reload nginx` | |
| 8 | Probar acceso web | https://immich.la-razon.com | |
| 9 | Configurar backup | Cron + test restore | |
| 10 | Configurar monitoreo | Prometheus + alertas | |
| 11 | Documentar accesos | URLs, credenciales (Vault) | |
| 12 | Capacitación usuarios | Sesión práctica + manuales | |

---

## 📚 Referencias

- **Documentación oficial:** https://immich.app/docs/
- **GitHub:** https://github.com/immich-app/immich
- **Hardware:** ThinkServer RD630 Specs
- **Backup:** BorgBackup Docs + Synology Hyper Backup

---

*Implementado por: Devin Richard Conde Mancilla*  
*SysAdmin Senior | Infraestructura & Seguridad*  
*Julio 2025*