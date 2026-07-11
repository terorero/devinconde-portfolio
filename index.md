---
layout: default
title: "Devin Conde Mancilla - Infrastructure Portfolio"
description: "Senior SysAdmin | Infrastructure Engineer | Security Specialist | 25+ years experience | La Paz, Bolivia"
---

# Devin Conde Mancilla - Infrastructure Portfolio

**Analista de Infraestructura y Seguridad Informática | SYSADMIN**  
25+ años experiencia | La Paz, Bolivia | Disponible  
🌐 https://www.devinconde.com | 💼 https://www.linkedin.com/in/devin-conde-mancilla-21038315

---

## 🎯 RESUMEN EJECUTIVO

| Métrica | Valor |
|---------|-------|
| **Experiencia** | 25+ años (1995-presente) |
| **Roles actuales** | Resp. Redes y Comunicaciones @ La Razón (2020-presente) |
| **Logro destacado** | Migración Exchange → Zimbra (0 licencias propietarias, 15 años CSBP) |
| **Stack core** | Linux/Windows/macOS, Zimbra, Proxmox, Docker, AWS, Fortinet, Asterisk, Synology |
| **Disponibilidad** | 24/7, Presencial/Remoto/Híbrido |
| **Idiomas** | ES (nativo), EN (técnico), AY (intermedio) |

---

## 💎 PROYECTOS DESTACADOS

### 1. **Linux Hardening Baseline** ⭐⭐⭐⭐⭐
Script de hardening idempotente (CIS + 25 años exp. producción)
- SSH: keys only, ciphers modernos, timeouts, banner
- Kernel sysctl: network, ASLR, ptrace, kexec, martians
- Filesystem: noexec/nosuid/nodev, sticky bits, módulos FS innecesarios
- Paquetes: auto-updates seguridad, remove servicios innecesarios
- Auditd: reglas CIS (identity, privileged cmds, file access, kernel modules)
- Logging: rsyslog permisos 640, rate limiting, RFC3339, logrotate 30d
- Fail2ban: SSH, recidive, nginx, apache, Zimbra, Postfix, Dovecot
- Usuarios: PASS_MAX_DAYS 90, PAM pwquality minlen=14, umask 027
- Sudo: logfile, log_input/output, timestamp_timeout=5, requiretty
- Firewall: firewalld drop zone / nftables baseline
- Docker: userns-remap, no-new-privileges, seccomp custom, log rotation
- Servicios: disable avahi, cups, dhcpd, nfs, rpcbind, named, etc.
- **Modos:** `--audit` (solo revisa) | `--apply` (aplica con confirmación "SI")

📁 `hardening/linux-hardening.sh` (~1,200 líneas)

---

### 2. **Monitoring Stack Production-Ready** ⭐⭐⭐⭐⭐
Stack completo Prometheus+Grafana+Alertmanager para 200+ usuarios
- **10 servicios**: Prometheus, Alertmanager, Grafana, Node Exporter, cAdvisor, Blackbox, Pushgateway, Zimbra Exporter, FortiGate Exporter
- **15+ scrape configs**: Linux, Docker, Zimbra, FortiGate, Blackbox HTTP/HTTPS/ICMP/TCP/DNS, Windows, DBs
- **50+ alertas**: Host, Containers, Zimbra, FortiGate, Blackbox, Prometheus, Backup, Seguridad
- **3 Dashboards**: Linux Host Overview, Zimbra Mail Server, FortiGate Firewall
- **Seguridad**: read-only containers, no-new-privileges, non-root users, secrets externos

📁 `monitoring/` (docker-compose.yml, prometheus.yml, alertmanager.yml, rules/alerts.yml, grafana-dashboards/)

---

### 3. **Infrastructure as Code (Ansible + Terraform)** ⭐⭐⭐⭐
- **Ansible**: 12 plays (bootstrap, zimbra, fortigate, swarm, k8s, monitoring, apps, security)
- **Roles**: common, ssh-hardening, firewall, monitoring, backup, docker, zimbra, fortigate, kubernetes
- **Terraform**: AWS (VPC, Bastion, AD, Zimbra, FortiGate-VM, VPN, Monitoring), DigitalOcean, modules reutilizables

📁 `infrastructure-as-code/`

---

### 4. **Backup & Disaster Recovery** ⭐⭐⭐⭐⭐
- **Borg Backup**: encriptado, dedup, compresión lz4, retención 7d/4w/12m/3y
- **Verificación automática**: extract dry-run, restore test mensual (primer lunes)
- **DRP Runbook**: RTO/RPO, 5 escenarios restore, failover cloud (Terraform), contactos emergencia
- **Synology Hyper Backup**: config secundaria

📁 `backup-dr/`

---

## 📊 MÉTRICAS DE VALOR PARA RECLUTADORES

| Proyecto | Líneas | Tecnologías | Valor demostrado |
|----------|--------|-------------|------------------|
| Linux Hardening | ~1,200 | Bash, systemd, auditd, nftables, PAM | Seguridad práctica, idempotencia, multi-distro |
| Monitoring Stack | ~800 YAML + Go | Docker, Prometheus, Grafana, Alertmanager, Blackbox | Observabilidad completa, alertas accionables |
| Ansible/Terraform | ~400 | Ansible, Terraform, AWS, Proxmox | IaC, GitOps, reproducibilidad |
| Backup/DR | ~600 | Borg, Shell, DR planning | Resiliencia, RTO/RPO, testing automatizado |

---

## 🔗 ENLACES RÁPIDOS

| Recurso | URL |
|---------|-----|
| **Web Personal** | https://www.devinconde.com |
| **CV Online** | https://www.devinconde.com/resumen.html |
| **Descargar CV PDF** | https://www.devinconde.com/resumen.html |
| **LinkedIn** | https://www.linkedin.com/in/devin-conde-mancilla-21038315 |
| **GitHub Portfolio** | https://github.com/terorero/devinconde-portfolio |
| **Contacto Directo** | +591 623 22510 / info@devinconde.com |

---

## 📌 ESTRUCTURA DEL REPOSITORIO

```
devinconde-portfolio/
├── hardening/
│   ├── linux-hardening.sh          # Hardening CIS + 25 años exp
│   └── README.md
├── monitoring/
│   ├── docker-compose.yml          # Stack 10 servicios
│   ├── prometheus.yml              # 15+ scrape configs
│   ├── alertmanager.yml            # Email/Slack/Webhook
│   ├── rules/alerts.yml            # 50+ alertas
│   ├── grafana-dashboards/         # 3 dashboards JSON
│   └── exporters/                  # Go sources (Zimbra, FortiGate)
├── infrastructure-as-code/
│   ├── ansible/
│   │   ├── site.yml                # 12 plays
│   │   └── roles/                  # 8+ roles
│   └── terraform/
│       ├── aws/                    # VPC, Bastion, AD, Zimbra, FortiGate, VPN
│       ├── digitalocean/
│       └── modules/                # linux-server, monitoring-stack
├── backup-dr/
│   ├── borg-backup.sh              # Backup prod (La Razón: 200+ users, 5TB+)
│   ├── drp-runbook.md              # Runbook completo RTO/RPO
│   └── excludes.lst
└── docs/                           # Architecture decisions, migrations
```

---

*Última actualización: 2026-07-11*  
*Generado con Jekyll + Minima theme en GitHub Pages*