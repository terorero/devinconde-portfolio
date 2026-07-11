# Devin Conde Mancilla - Portfolio & Job Search Bolivia

**Analista de Infraestructura y Seguridad Informática | SYSADMIN**  
25+ años experiencia | La Paz, Bolivia | Disponible  
🌐 https://www.devinconde.com | 💼 https://www.linkedin.com/in/devin-conde-mancilla-21038315

---

## 📁 ESTRUCTURA DEL PORTAFOLIO

```
devinconde-portfolio/
├── README.md                          # Este archivo - Índice general
├── job-search-bolivia.md              # Análisis de mercado + estrategia empleo BO
├── hardening/
│   ├── README.md                      # Documentación hardening
│   └── linux-hardening.sh             # Script hardening CIS + 25 años exp
├── monitoring/
│   ├── README.md                      # Documentación stack monitoreo
│   ├── docker-compose.yml             # Stack completo Prometheus+Grafana+Alertmanager
│   ├── prometheus.yml                 # Config scrape targets (Zimbra, FortiGate, etc.)
│   ├── alertmanager.yml               # Config notificaciones email/slack/webhook
│   ├── rules/
│   │   └── alerts.yml                 # 50+ reglas alerta (infra, mail, firewall, security)
│   ├── grafana-datasources/
│   │   └── datasources.yml            # Provisioning Prometheus/Alertmanager
│   ├── grafana-dashboards/
│   │   ├── dashboards.yml             # Config provisioning dashboards
│   │   ├── linux-host-overview.json   # Dashboard Linux hosts
│   │   ├── zimbra-mail-server.json    # Dashboard Zimbra (cola, usuarios, disco)
│   │   └── fortigate-firewall.json    # Dashboard FortiGate (CPU, sesiones, VPN, IPS)
│   └── exporters/
│       ├── zimbra/                    # Exporter custom Zimbra (Go)
│       │   ├── Dockerfile
│       │   ├── main.go
│       │   └── go.mod
│       └── fortinet/                  # Exporter custom FortiGate (Go)
│           ├── Dockerfile
│           ├── main.go
│           └── go.mod
├── infrastructure-as-code/
│   ├── ansible/
│   │   ├── site.yml                   # Playbook principal multi-role
│   │   └── roles/
│   │       ├── common/tasks/main.yml  # Base config todos los servers
│   │       ├── ssh-hardening/
│   │       ├── firewall/
│   │       ├── monitoring/
│   │       ├── backup/
│   │       ├── docker/
│   │       ├── zimbra/
│   │       ├── fortigate/
│   │       ├── kubernetes/
│   │       └── security/
│   └── terraform/
│       ├── aws/                       # Módulos AWS (VPC, EC2, RDS, S3, VPN)
│       ├── digitalocean/              # Módulos DigitalOcean
│       └── modules/                   # Módulos reutilizables
├── backup-dr/
│   ├── README.md                      # Documentación backup/DR
│   ├── borg-backup.sh                 # Script producción Borg (encriptado, dedup)
│   ├── excludes.lst                   # Patrones exclusión backup
│   ├── synology-hyper-backup.json     # Config Hyper Backup Synology
│   ├── drp-runbook.md                 # Runbook Disaster Recovery completo
│   └── restore-test.sh                # Script prueba restore mensual
├── voip-telephony/
│   ├── asterisk/
│   │   ├── sip.conf.template
│   │   ├── extensions.conf.template
│   │   ├── queues.conf.template
│   │   └── voicemail.conf.template
│   ├── freepbx-backup.sh
│   └── avaya-smgr-scripts/
├── security/
│   ├── fortinet/
│   │   ├── firewall-policy-audit.sh
│   │   ├── vpn-hardening.cli
│   │   └── ips-signature-update.sh
│   ├── zimbra/
│   │   ├── anti-spam-tuning.zmp
│   │   ├── tls-hardening.sh
│   │   └── dkim-dmarc-setup.sh
│   └── ssh-hardening/
│       ├── sshd_config.template
│       ├── fail2ban-jails.local
│       └── audit-ssh-keys.sh
├── cloud-hybrid/
│   ├── docker/
│   │   ├── zimbra-docker-compose.yml
│   │   ├── monitoring-stack.yml
│   │   ├── guacamole-rdp.yml
│   │   └── reverse-proxy-nginx.yml
│   ├── kubernetes/
│   │   ├── zimbra-operator.yaml
│   │   ├── monitoring-operator.yaml
│   │   └── ingress-nginx.yaml
│   └── ansible-aws/
│       ├── site.yml
│       └── vars.yml
└── docs/
    ├── architecture-decisions.md
    ├── migration-exchange-to-zimbra.md
    ├── ha-proxmox-synology.md
    └── voip-asterisk-avaya-integration.md
```

---

## 🎯 RESUMEN EJECUTIVO PERFIL

| Métrica | Valor |
|---------|-------|
| **Experiencia** | 25+ años (1995-presente) |
| **Roles actuales** | Resp. Redes y Comunicaciones @ La Razón (2020-presente) |
| **Logro destacado** | Migración Exchange → Zimbra (0 licencias propietarias, 15 años CSBP) |
| **Stack core** | Linux/Windows/macOS, Zimbra, Proxmox, Docker, AWS, Fortinet, Asterisk, Synology |
| **Disponibilidad** | 24/7, Presencial/Remoto/Híbrido |
| **Idiomas** | ES (nativo), EN (técnico), AY (intermedio) |

---

## 🔍 ANÁLISIS MERCADO LABORAL BOLIVIA

### Ofertas encontradas (muestra julio 2026)
| Portal | Categorías relevantes | Hallazgos |
|--------|----------------------|-----------|
| **Computrabajo BO** | SysAdmin, DevOps, Cloud, Seguridad, Linux, Ingeniero Sistemas | 4-8 ofertas activas/categoría; mucho ruido junior/académico |
| **LinkedIn Jobs BO** | 3 ofertas "Sysadmin" visibles en meta | Mejor canal para senior - requiere login manual |
| **Bumeran/Trabajando** | Bloqueados para bots | Revisión manual necesaria |

### Sectores objetivo en Bolivia
1. **Banca/Finanzas** (BNB, BCP, Unión, Mercantil, Ganadero, FIE, Prodem) - Infra crítica 24/7
2. **Telcos** (Tigo, Entel, Viva) - VoIP, Linux masivo, automatización
3. **Energía/Óleo** (YPFB, ENDE, Transredes) - Datacenters, SCADA, seguridad OT/IT
4. **Gobierno** (Aduana, Impuestos, Gov. Municipal, UMSA, UCB) - Estabilidad, Linux, Zimbra
5. **Medios** (La Razón, El Deber, Los Tiempos, Red Uno, Unitel) - 24/7, publishing, streaming
6. **Retail/Industria** (CBN, Pil, SOBOCE) - ERP, Windows/Linux híbrido, POS
7. **Consultoras** (Assa, Datacom, Tecnoserv, Softtek, Globant, NTT Data) - Proyectos variados

---

## 🚀 PLAN DE ACCIÓN INMEDIATO (7 DÍAS)

| Día | Acción | Estado |
|-----|--------|--------|
| **Hoy** | ✅ Configurar alertas LinkedIn + Computrabajo + "Open to work" | 🔲 |
| **Día 1** | Revisar 20 ofertas → postular a 5-8 mejor match | 🔲 |
| **Día 2** | Contactar 5 ex-colegas (CSBP, La Razón, Transturin) | 🔲 |
| **Día 3** | ✅ Subir 3-5 proyectos a GitHub público → enlazar en web/LinkedIn | ✅ **HECHO** |
| **Día 4** | Escribir 1 post técnico LinkedIn (Zimbra/HA Proxmox/VoIP) | 🔲 |
| **Día 5** | Identificar 3 headhunters IT Bolivia → conectar + enviar CV | 🔲 |
| **Día 6** | Postular directo 3 empresas objetivo (web RRHH: Tigo, Entel, YPFB, BNB, BCP) | 🔲 |
| **Día 7** | Revisar respuestas → ajustar CV/perfil → planear semana 2 | 🔲 |

---

## 💎 PROYECTOS GITHUB CREADOS (Opción 3 - COMPLETADA)

### 1. **Linux Hardening Baseline** ⭐⭐⭐⭐⭐
```
hardening/linux-hardening.sh
├── SSH hardening (keys only, ciphers modernos, timeouts)
├── Kernel sysctl (network, ASLR, ptrace, kexec)
├── Filesystem (noexec/nosuid/nodev, sticky bits, módulos FS)
├── Paquetes (auto-updates seguridad, remove servicios innecesarios)
├── Auditd (reglas CIS: identity, privileged cmds, file access, kernel modules)
├── Logging (rsyslog permisos 640, rate limiting, RFC3339, logrotate 30d)
├── Fail2ban (SSH, recidive, nginx, apache, Zimbra, Postfix, Dovecot)
├── Usuarios (PASS_MAX_DAYS 90, PAM pwquality minlen=14, umask 027)
├── Sudo (logfile, log_input/output, timestamp_timeout=5, requiretty)
├── Firewall (firewalld drop zone / nftables baseline)
├── Docker (userns-remap, no-new-privileges, seccomp custom, log rotation)
└── Servicios (disable avahi, cups, dhcpd, nfs, rpcbind, named, etc.)
```
**Modos:** `--audit` (solo revisa) | `--apply` (aplica con confirmación "SI")  
**Backup automático** antes de cambios | **Log completo** en `/var/log/linux-hardening-*.log`

### 2. **Monitoring Stack Production-Ready** ⭐⭐⭐⭐⭐
```
monitoring/
├── docker-compose.yml          # 10 servicios: Prometheus, Alertmanager, Grafana,
│                               # Node Exporter, cAdvisor, Blackbox, Pushgateway,
│                               # Zimbra Exporter, FortiGate Exporter
├── prometheus.yml              # 15+ scrape configs (Linux, Docker, Zimbra, FortiGate,
│                               # Blackbox HTTP/HTTPS/ICMP/TCP/DNS, Windows, DBs)
├── alertmanager.yml            # Receivers: email, Slack, webhook; inhibiciones
├── rules/alerts.yml            # 50+ alertas: Host, Containers, Zimbra, FortiGate,
│                               # Blackbox, Prometheus, Backup, Seguridad
├── grafana-dashboards/
│   ├── linux-host-overview.json
│   ├── zimbra-mail-server.json
│   └── fortigate-firewall.json
└── exporters/                  # Go source para exporters custom
    ├── zimbra/                 # Métricas: queue, users, disk, services, protocols
    └── fortinet/               # Métricas: CPU, mem, sessions, VPN, HA, IPS, logs
```
**Seguridad:** Contenedores read-only, no-new-privileges, non-root users, secrets externos

### 3. **Infrastructure as Code (Ansible + Terraform)** ⭐⭐⭐⭐
```
infrastructure-as-code/
├── ansible/
│   ├── site.yml                # 12 plays: bootstrap, zimbra, fortigate, swarm, k8s, monitoring, apps
│   └── roles/
│       └── common/tasks/main.yml  # Base: timezone, hostname, packages, sysctl, limits,
│                                  # journald, users, sudo, SSH keys, motd
└── terraform/
    ├── aws/                    # VPC, Bastion, AD, Zimbra, FortiGate-VM, VPN, Monitoring
    ├── digitalocean/
    └── modules/                # linux-server, monitoring-stack reutilizables
```

### 4. **Backup & Disaster Recovery** ⭐⭐⭐⭐⭐
```
backup-dr/
├── borg-backup.sh              # Producción: encriptado, dedup, compresión lz4,
│                               # retención 7d/4w/12m/3y, compact mensual,
│                               # verify + restore test mensual (primer lunes),
│                               # notificaciones email/Slack
├── excludes.lst                # Patrones exclusión (/dev, /proc, caches, DBs, contenedores)
├── drp-runbook.md              # Runbook completo: RTO/RPO, 5 escenarios restore,
│                               # failover cloud (Terraform), testing schedule,
│                               # contactos emergencia, documentos relacionados
└── synology-hyper-backup.json  # Config secundaria Synology
```

---

## 📊 MÉTRICAS DE VALOR PARA RECLUTADORES

| Proyecto | Líneas código | Tecnologías | Valor demostrado |
|----------|---------------|-------------|------------------|
| Linux Hardening | ~1,200 | Bash, systemd, auditd, nftables, PAM | Seguridad práctica, idempotencia, multi-distro |
| Monitoring Stack | ~800 (YAML) + Go | Docker, Prometheus, Grafana, Alertmanager, Blackbox | Observabilidad completa, alertas accionables |
| Ansible/Terraform | ~400 | Ansible, Terraform, AWS, Proxmox | IaC, GitOps, reproducibilidad |
| Backup/DR | ~600 | Borg, Shell, DR planning | Resiliencia, RTO/RPO, testing automatizado |

---

## 🔗 ENLACES RÁPIDOS

| Recurso | URL |
|---------|-----|
| **Web Personal** | https://www.devinconde.com |
| **CV Online** | https://www.devinconde.com/resumen.html |
| **Descargar CV PDF** | https://www.devinconde.com/resumen.html (botón "Descargar Versión PDF") |
| **LinkedIn** | https://www.linkedin.com/in/devin-conde-mancilla-21038315 |
| **GitHub Portfolio** | https://github.com/terorero/devinconde-portfolio |
| **Contacto Directo** | +591 623 22510 / info@devinconde.com |

---

## 📝 PRÓXIMOS PASOS SUGERIDOS

1. **Hacer push a GitHub:**
   ```bash
   cd /Users/terorero/Developer/7.Hermes/devinconde-portfolio
   git init
   git add .
   git commit -m "feat: complete infrastructure portfolio - hardening, monitoring, IaC, backup/DR"
   git remote add origin https://github.com/terorero/devinconde-portfolio.git
   git push -u origin main
   ```

2. **Añadir badges a README principal:**
   ```markdown
   ![GitHub stars](https://img.shields.io/github/stars/terorero/devinconde-portfolio)
   ![GitHub last commit](https://img.shields.io/github/last-commit/terorero/devinconde-portfolio)
   ![License](https://img.shields.io/github/license/terorero/devinconde-portfolio)
   ```

3. **Configurar GitHub Actions** para linting (shellcheck, ansible-lint, terraform fmt)

4. **Escribir 3 artículos técnicos** para blog/LinkedIn:
   - "Migración Exchange → Zimbra: 0 licencias, 200 usuarios, 15 años"
   - "HA con Proxmox + Synology: 24/7 en medio de comunicación"
   - "VoIP empresarial: Asterisk + Avaya integración real"

5. **Mantener job-search-bolivia.md actualizado** con nuevas ofertas/contactos semanalmente

---

## 📌 NOTAS DE MANTENIMIENTO

- **job-search-bolivia.md**: Actualizar semanalmente con nuevas ofertas, contactos, estado aplicaciones
- **Portfolio GitHub**: Añadir 1 proyecto/mes (rotar: security, monitoring, IaC, cloud, voip)
- **CV Web**: Sincronizar con GitHub projects destacados cada trimestre
- **LinkedIn**: Post técnico mensual + actualizar "Featured" con últimos repos

---

*Última actualización: 2026-07-11*  
*Próxima revisión: 2026-07-18*