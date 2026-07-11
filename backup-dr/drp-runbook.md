# Disaster Recovery Plan (DRP) Runbook
**Sistema:** Infraestructura Crítica - La Razón / CSBP / Consultoría  
**Autor:** Devin Richard Conde Mancilla  
**Versión:** 1.0  
**Fecha:** 2026-07-11  
**Clasificación:** CONFIDENCIAL - Solo equipo de infraestructura

---

## 📋 RESUMEN EJECUTIVO

Este documento describe los procedimientos de recuperación ante desastres para la infraestructura crítica administrada. Cubre escenarios de pérdida total de sitio, fallo de hardware crítico, ransomware, y corrupción de datos.

**RTO Objetivo:** 4 horas (sitio completo) / 1 hora (servicios críticos)  
**RPO Objetivo:** 1 hora (datos críticos) / 24 horas (datos no críticos)  
**Frecuencia de prueba:** Mensual (restore test) / Trimestral (full DR drill)

---

## 🎯 SERVICIOS CRÍTICOS (Prioridad de recuperación)

| Prioridad | Servicio | RTO | RPO | Descripción |
|-----------|----------|-----|-----|-------------|
| **P0** | **Zimbra Mail** | 1h | 1h | Correo empresarial 200+ usuarios |
| **P0** | **Firewall FortiGate** | 30m | 0m | Perímetro de seguridad, VPN, HA |
| **P0** | **Active Directory / DNS** | 1h | 1h | Autenticación, autorización, resolución |
| **P1** | **SAP R/3** | 4h | 4h | ERP financiero/logístico |
| **P1** | **VoIP Avaya/Asterisk** | 2h | 1h | Telefonía corporativa |
| **P1** | **File Server (Synology)** | 4h | 24h | Datos usuarios, compartidos |
| **P2** | **Monitoring (Prometheus/Grafana)** | 8h | 24h | Observabilidad |
| **P2** | **Backup (Borg/Repository)** | 24h | 24h | Capacidad de restore |
| **P3** | **Web/CMS (WordPress/Joomla)** | 24h | 24h | Sitios públicos/intranet |

---

## 🏗 ARQUITECTURA DE BACKUP

```
┌─────────────────────────────────────────────────────────────────┐
                    PRODUCCIÓN (La Paz)
├─────────────────────────────────────────────────────────────────┤
│  Blade Servers + Synology DS317+ (Primary Storage)             │
│  ├── Zimbra (Mail)                                              │
│  ├── AD/DNS/DHCP                                                │
│  ├── File Shares                                                │
│   SAP DB                                                        │
│  └── VMs (Proxmox)                                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Borg Backup (Encrypted, Deduplicated)
                           │ Schedule: Daily 02:00 + Hourly incrementals
                           ▼
┌─────────────────────────────────────────────────────────────────┐
                    SITIO REMOTO / CLOUD (DR Site)
├─────────────────────────────────────────────────────────────────┤
│  AWS us-east-1 / DigitalOcean / Sitio físico alternativo       │
│  ├── Borg Repository (S3/NFS/SSH)                              │
│  ├── Synology Hyper Backup (Secondary)                         │
│  └── Zimbra Native Backup (zmbackup)                           │
└─────────────────────────────────────────────────────────────────┘
```

**Estrategia 3-2-1:**
- ✅ 3 copias de datos (Producción + Borg Repo + Synology Hyper Backup)
- ✅ 2 medios diferentes (Disk + Object Storage/Cloud)
- ✅ 1 offsite (AWS/DO/Sitio alternativo)

---

## 🔐 CREDENCIALES Y ACCESOS (Guardar en Vault/Keepass)

| Sistema | Usuario | Método | Ubicación |
|---------|---------|--------|-----------|
| Borg Repo | `borg` | SSH Key + Passphrase | Vault: `infra/backup/borg` |
| Synology DSM | `admin` | HTTPS + 2FA | Vault: `infra/storage/synology` |
| FortiGate | `admin` | HTTPS + SSH Key | Vault: `infra/network/fortigate` |
| Zimbra | `admin` | Web UI + CLI | Vault: `infra/mail/zimbra` |
| Proxmox | `root@pam` | HTTPS + SSH Key | Vault: `infra/virt/proxmox` |
| AWS/Cloud | `infra-backup` | IAM Access Keys | Vault: `infra/cloud/aws` |
| Vaultwarden | `admin` | Web + TOTP | Vault: `infra/secrets/vaultwarden` |

---

## 📦 PROCEDIMIENTOS DE RESTORE

### ESCENARIO 1: Restore de archivo/carpeta individual (Borg)

```bash
# 1. Conectar al repo
export BORG_REPO=ssh://borg@backup.example.com:/volume1/borg-backups/la-razon
export BORG_PASSPHRASE=$(vault read -field=passphrase infra/backup/borg)

# 2. Listar backups disponibles
borg list $BORG_REPO --last 10

# 3. Extraer archivo específico
borg extract $BORG_REPO::la-razon-2026-07-10T02:00:00 /etc/zimbra/localconfig.xml --path /tmp/restore/

# 4. Verificar y copiar
cat /tmp/restore/etc/zimbra/localconfig.xml
cp /tmp/restore/etc/zimbra/localconfig.xml /etc/zimbra/
```

### ESCENARIO 2: Restore completo de servidor Linux (Bare Metal)

```bash
# 1. Boot desde SystemRescueCD / Ubuntu Live USB
# 2. Particionar disco (igual que original)
# 3. Montar filesystems
mount /dev/sda2 /mnt
mount /dev/sda1 /mnt/boot
# ... montar /home, /var, /opt, etc.

# 4. Restaurar desde Borg
export BORG_REPO=ssh://borg@backup.example.com:/volume1/borg-backups/la-razon
export BORG_PASSPHRASE=...
borg extract --numeric-ids $BORG_REPO::la-razon-2026-07-10T02:00:00 /mnt

# 5. Reinstalar bootloader
arch-chroot /mnt
grub-install /dev/sda
update-grub
exit

# 6. Reboot
reboot
```

### ESCENARIO 3: Restore Zimbra Mail Server

```bash
# OPCIÓN A: Zimbra Native Backup (zmrestore)
# 1. Instalar Zimbra fresh (same version)
# 2. Detener servicios
zmcontrol stop

# 3. Restore desde backup nativo
/opt/zimbra/bin/zmrestore -a all -t /backup/zimbra/full-20260710 -lb /backup/zimbra/full-20260710/backup.log

# 4. Iniciar y verificar
zmcontrol start
zmcontrol status

# OPCIÓN B: Borg Backup (full server restore + Zimbra data)
# Ver ESCENARIO 2, luego:
# - Verificar /opt/zimbra restaurado
# - Ejecutar: /opt/zimbra/libexec/zmfixperms
# - Iniciar: zmcontrol start
```

### ESCENARIO 4: Restore FortiGate Firewall

```bash
# 1. Conectar por consola serie al FortiGate nuevo
# 2. Configurar IP management temporal
config system interface
    edit "mgmt1"
        set ip 192.168.1.99/24
    next
end

# 3. Restore desde backup (TFTP/SCP/USB)
execute restore config tftp backup-config.conf 192.168.1.100

# 4. O desde FortiManager
execute restore config fmg backup-config.conf

# 5. Verificar HA sync
get system ha status
# Debe mostrar: "Master/Primary" y "In-sync"

# 6. Verificar VPNs, políticas, routing
get router info routing-table all
diagnose vpn tunnel list
```

### ESCENARIO 5: Recuperación ante Ransomware

```bash
# 1. AISLAR inmediatamente
# - Desconectar red afectada (VLAN quarantine)
# - Bloquear IPs en FortiGate
# - Deshabilitar cuentas comprometidas en AD

# 2. IDENTIFICAR alcance
# - Verificar logs: /var/log/auth.log, /var/log/secure, FortiGate logs
# - Determinar vector inicial (phishing, RDP, VPN, exploit)
# - Identificar extensión de cifrado (.lockbit, .ransom, etc.)

# 3. VERIFICAR BACKUPS no comprometidos
# - Comprobar repositorio Borg: borg check -v $REPO
# - Verificar integridad: borg extract --dry-run $REPO::latest
# - Si repo comprometido → usar Synology Hyper Backup / AWS snapshot

# 4. RESTORE desde backup limpio (pre-infección)
# - Identificar último backup limpio (fecha anterior a infección)
# - Restore selectivo de datos críticos (no binarios)
# - Reconstruir servidores desde cero (imagen gold + config management)

# 5. POST-INCIDENT
# - Rotar TODAS las credenciales (Vault, SSH keys, service accounts)
# - Revisar hardening (ejecutar linux-hardening.sh --apply)
# - Reportar a autoridades (CERT Bolivia, Policía Cibernética)
# - Documentar lecciones aprendidas
```

---

## ☁️ FAILOVER A SITIO CLOUD (AWS/DigitalOcean)

### Infraestructura como Código (Terraform)

```bash
# 1. Clonar repo IaC
git clone https://github.com/terorero/devinconde-portfolio.git
cd devinconde-portfolio/infrastructure-as-code/terraform/aws

# 2. Configurar variables
cp terraform.tfvars.example terraform.tfvars
# Editar: region, vpc_cidr, ssh_key, backup_repo_url

# 3. Deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 4. Configurar Ansible para post-provision
cd ../../ansible
ansible-playbook -i inventory/aws.yml site.yml --limit dr-site
```

### Servicios a levantar en DR Cloud (orden de prioridad)

| Orden | Servicio | Terraform Module | Ansible Role | Tiempo est. |
|-------|----------|------------------|--------------|-------------|
| 1 | VPC + Security Groups | `vpc` | - | 5 min |
| 2 | Bastion Host | `bastion` | `bastion` | 5 min |
| 3 | AD/DNS (Windows) | `ad-dc` | `windows-ad` | 30 min |
| 4 | Zimbra (Ubuntu) | `zimbra` | `zimbra-server` | 45 min |
| 5 | FortiGate-VM (HA) | `fortigate` | - | 20 min |
| 6 | File Server (Synology Cloud Sync) | `efs` | `synology-sync` | 15 min |
| 7 | Monitoring | `monitoring` | `prometheus-grafana` | 20 min |
| 8 | VPN Site-to-Site | `vpn` | `fortigate-vpn` | 15 min |

---

## 🧪 PRUEBAS DE RECUPERACIÓN (Testing Schedule)

| Frecuencia | Tipo | Alcance | Responsable | Evidencia |
|------------|------|---------|-------------|-----------|
| **Diaria** | Automated | Borg check + extract dry-run | Cron + Monitoring | Alertmanager/Email |
| **Semanal** | Manual | Restore 5 archivos aleatorios | SysAdmin On-call | Ticket + Log |
| **Mensual** | Manual | **Restore test completo** (VM + Zimbra + AD) | Team Lead | Documento + Video |
| **Trimestral** | Simulacro | **Full DR Drill** (Failover a cloud, 4h RTO) | Todo el equipo | After-action report |
| **Anual** | Auditoría | Revisión completa DRP, actualizar docs | CISO / Auditor | Informe formal |

### Checklist Mensual de Restore Test

```markdown
- [ ] Seleccionar backup aleatorio (últimos 30 días)
- [ ] Restore VM Linux completa en entorno aislado (Proxmox test cluster)
- [ ] Verificar: SSH, servicios, logs, conectividad
- [ ] Restore Zimbra: verificar buzones, cola MTA, webmail
- [ ] Restore AD: verificar usuarios, GPOs, replicación
- [ ] Restore FortiGate config: verificar HA, VPNs, políticas
- [ ] Documentar tiempo real de restore (RTO real)
- [ ] Comparar RTO real vs objetivo
- [ ] Actualizar runbook si hay desviaciones > 20%
- [ ] Firmar acta por Team Lead
```

---

## 📞 CONTACTOS DE EMERGENCIA

| Rol | Nombre | Teléfono | Email | Disponibilidad |
|-----|--------|----------|-------|----------------|
| **Infra Lead** | Devin Conde | +591 623 22510 | devin@devinconde.com | 24/7 |
| **SysAdmin Senior** | [Nombre] | +591 XXX XXXXX | admin@empresa.com | 24/7 |
| **Security** | [Nombre] | +591 XXX XXXXX | sec@empresa.com | 24/7 |
| **Vendor: Fortinet** | TAC Bolivia | +591 2 XXXXXXX | tac.bo@fortinet.com | Business hours |
| **Vendor: Zimbra** | Support | Portal | support@zimbra.com | 24/7 (Enterprise) |
| **Vendor: Synology** | Support | Portal | support@synology.com | Business hours |
| **Cloud: AWS** | Enterprise Support | Portal | AWS Console | 24/7 |
| **CERT Bolivia** | Equipo de respuesta | +591 2 XXXXXXX | cert@cert.bo | 24/7 |
| **Policía Cibernética** | FELCC | 110 / +591 2 XXXXXXX | cibernetica@policiabolivia.bo | 24/7 |

---

## 📄 DOCUMENTOS RELACIONADOS

| Documento | Ubicación | Última actualización |
|-----------|-----------|---------------------|
| Network Diagram | `/docs/architecture/network-topology.drawio` | 2026-06 |
| Server Inventory | `/docs/inventory/servers.csv` | 2026-07 |
| Credential Vault | Vaultwarden: `Infra/Production` | Daily |
| Change Log | GitHub: `devinconde-portfolio/infrastructure` | Per change |
| Monitoring Runbooks | `/monitoring/runbooks/` | 2026-06 |
| Hardening Baseline | `hardening/linux-hardening.sh` | 2026-07 |

---

## 📝 REGISTRO DE CAMBIOS

| Fecha | Versión | Autor | Cambios |
|-------|---------|-------|---------|
| 2026-07-11 | 1.0 | Devin Conde | Versión inicial - DRP completo |

---

## ✅ APROBACIÓN

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Infra Lead** | Devin Richard Conde Mancilla | _______________ | __________ |
| **Gerencia TI** | [Nombre] | _______________ | __________ |
| **Seguridad** | [Nombre] | _______________ | __________ |
| **Dirección** | [Nombre] | _______________ | __________ |

---

*Fin del documento - DRP Runbook v1.0*