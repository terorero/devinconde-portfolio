# Monitoring Stack - Production Ready

Stack completo de monitoreo: **Prometheus + Grafana + Alertmanager + Exporters** listo para producción 200+ usuarios.

## Características

- **Multi-target**: Linux hosts, Docker containers, Zimbra, FortiGate, Blackbox probing
- **High Availability**: Configurado para HA (múltiples réplicas, persistence)
- **Security**: Read-only containers, no-new-privileges, secrets management, non-root users
- **Alerting**: 50+ reglas de alerta cubriendo infra, mail, firewall, seguridad, backups
- **Dashboards**: Pre-provisionados para Zimbra, FortiGate, Linux, Docker, Kubernetes
- **Retención**: 30 días métricas, 120 días alertas, 10GB límite Prometheus

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
                        MONITORING STACK
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  Prometheus  │◄───│ Alertmanager │    │   Grafana    │      │
│  │   (TSDB)     │    │  (Alerting)  │    │ (Dashboards) │      │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘      │
│         │                   │                   │              │
│         ▼                   │                   │              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  EXPORTERS / TARGETS                     │   │
│  ├────────────┬────────────┬────────────┬──────────────────┤   │
│  │ Node       │ cAdvisor   │ Blackbox   │ Custom Exporters  │   │
│  │ Exporter   │            │ Exporter   │ • Zimbra          │   │
│  │            │            │            │ • FortiGate       │   │
│  │            │            │            │ • PostgreSQL      │   │
│  │            │            │            │ • Redis           │   │
│  └────────────┴────────────┴────────────┴──────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Inicio Rápido

### Prerrequisitos
- Docker 24+ / Docker Compose v2+
- 4GB RAM mínimo (8GB recomendado)
- 20GB disco para métricas (Prometheus)
- Puertos: 3000 (Grafana), 9090 (Prometheus), 9093 (Alertmanager), 9100 (Node Exporter)

### 1. Clonar y configurar

```bash
git clone https://github.com/terorero/devinconde-portfolio.git
cd devinconde-portfolio/monitoring
```

### 2. Crear secrets (OBLIGATORIO antes de deploy)

```bash
mkdir -p secrets

# Grafana admin password
echo "tu_password_seguro_aqui" > secrets/grafana_password.txt

# Zimbra admin password (para exporter)
echo "zimbra_admin_password" > secrets/zimbra_password.txt

# FortiGate API password
echo "fortigate_api_password" > secrets/fortigate_password.txt

chmod 600 secrets/*.txt
```

### 3. Configurar targets (editar prometheus.yml)

```yaml
# En prometheus.yml, actualizar:
static_configs:
  - targets: ['node-exporter:9100']
    labels:
      role: 'infra-server'
      os: 'linux'
```

### 4. Deploy

```bash
# Development
docker compose up -d

# Production (con Swarm/K8s)
docker stack deploy -c docker-compose.yml monitoring
```

### 5. Acceder

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Grafana | http://localhost:3000 | admin / (secret) |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |
| Node Exporter | http://localhost:9100/metrics | - |

## Estructura del Proyecto

```
monitoring/
├── docker-compose.yml          # Stack completo
├── prometheus.yml              # Config Prometheus + scrape configs
├── alertmanager.yml            # Config Alertmanager + receivers
├── rules/
│   └── alerts.yml              # 50+ reglas de alerta
├── grafana-dashboards/
│   ├── zimbra-mail-server.json
│   ├── fortigate-firewall.json
│   ├── linux-host-overview.json
│   ├── docker-containers.json
│   └── kubernetes-cluster.json
├── grafana-datasources/
│   └── datasources.yml
├── grafana.ini                 # Config Grafana
├── blackbox.yml                # Config Blackbox Exporter
├── exporters/
│   ├── zimbra/                 # Custom Zimbra exporter
│   │   ├── Dockerfile
│   │   ├── main.go
│   │   └── go.mod
│   └── fortinet/               # Custom FortiGate exporter
│       ├── Dockerfile
│       ├── main.go
│       └── go.mod
└── secrets/                    # (gitignored) Passwords, tokens
    ├── grafana_password.txt
    ├── zimbra_password.txt
    └── fortigate_password.txt
```

## Exporters Personalizados

### Zimbra Exporter
Métricas expuestas:
- `zimbra_mta_queue_size` - Cola de mensajes
- `zimbra_mta_received_total` / `sent_total` / `deferred_total` / `bounced_total`
- `zimbra_active_users` - Usuarios activos
- `zimbra_connected_clients` - Clientes conectados (IMAP/POP/SMTP/HTTP)
- `zimbra_disk_used_bytes` / `zimbra_disk_total_bytes`
- `zimbra_ldap_up`, `zimbra_mailboxd_up`, `zimbra_mta_up`, `zimbra_logger_up`
- `zimbra_amavis_queue_size`
- Protocolos: `zimbra_imap_commands_total`, `zimbra_pop_commands_total`, `zimbra_smtp_commands_total`, `zimbra_http_requests_total`

### FortiGate Exporter
Métricas expuestas:
- `fortigate_cpu_usage`, `fortigate_memory_usage`
- `fortigate_session_count`, `fortigate_session_limit`
- `fortigate_ssl_vpn_users`, `fortigate_ipsec_vpn_tunnels`
- `fortigate_interface_bytes_in_total`, `bytes_out_total`
- `fortigate_ips_detection_total` (por severidad)
- `fortigate_firewall_logs_total`, `webfilter_logs_total`, `antivirus_logs_total`
- `fortigate_ha_sync_status` (0=out of sync, 1=in sync)
- `fortigate_log_disk_usage`

## Reglas de Alerta (resumen)

| Categoría | Alertas | Severidad |
|-----------|---------|-----------|
| **Host/Infra** | HostDown, CPU, Memory, Disk, Load, Swap, FD, Time sync | warning/critical |
| **Contenedores** | ContainerDown, HighCPU, HighMemory, OOMKilled, RestartLoop | warning/critical |
| **Zimbra** | Down, QueueHigh/Critical, DiskUsage, LDAP/Mailboxd Down, AntiSpam Queue | warning/critical |
| **FortiGate** | Down, HighCPU/Memory, SessionHigh, VPNUsersHigh, HAOutOfSync, LogDiskHigh | warning/critical |
| **Blackbox** | ProbeFailed, ProbeSlow, HTTPDown, CertExpiring/Expired, ICMPDown, TCPDown | warning/critical |
| **Prometheus** | ConfigReloadFailed, TargetsDown, RuleEvalFailures, TSDBReloadFailures, DiskSpace | warning/critical |
| **Backup** | JobFailed, JobOld (>2d), RepoSizeHigh | critical/warning |
| **Seguridad** | SSHBruteForce, SudoFailures, AuditdDown, FirewallReloadFailed, UnauthorizedAccess | critical/warning |

## Notificaciones

Configurados receivers para:
- **Email** (SMTP con TLS)
- **Slack** (webhook)
- **Webhook** genérico (para integración con PagerDuty, Opsgenie, etc.)

## Mantenimiento

### Backup Prometheus
```bash
# Snapshot instantáneo
curl -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot

# Backup completo (detener Prometheus)
tar -czf prometheus-backup-$(date +%Y%m%d).tar.gz prometheus-data/
```

### Upgrade
```bash
docker compose pull
docker compose up -d --remove-orphans
```

### Logs
```bash
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f alertmanager
```

## Seguridad

- ✅ Contenedores read-only + no-new-privileges
- ✅ Usuarios no-root (UID 65534, 472)
- ✅ Secrets externos (no en imagen ni compose)
- ✅ Red interna `monitoring-network` (bridge)
- ✅ Healthchecks en todos los servicios
- ✅ Rate limiting en Blackbox
- ✅ Retención y limpieza automática

## Troubleshooting

| Problema | Solución |
|----------|----------|
| Prometheus OOM | Aumentar `--storage.tsdb.retention.size` o memoria |
| Targets DOWN | Verificar conectividad red, firewall, endpoint `/metrics` |
| Alertas no disparan | Revisar `alertmanager.yml` receivers, inhibiciones |
| Grafana "No data" | Verificar datasource provisioning, query correcta |
| Exporter custom falla | `docker compose logs zimbra-exporter` / `fortinet-exporter` |

## Roadmap

- [ ] Exporter PostgreSQL/MySQL
- [ ] Exporter Kubernetes (kube-state-metrics)
- [ ] Dashboards: Kubernetes, PostgreSQL, Redis, Kafka
- [ ] Integración PagerDuty/Opsgenie
- [ ] Cortex/Thanos para long-term storage multi-cluster
- [ ] GitOps con ArgoCD/Flux

## Autor

**Devin Richard Conde Mancilla**  
Analista de Infraestructura y Seguridad Informática | SYSADMIN  
25+ años experiencia | La Paz, Bolivia  
🌐 https://www.devinconde.com  
💼 https://www.linkedin.com/in/devin-conde-mancilla-21038315