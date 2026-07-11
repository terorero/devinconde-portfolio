# Linux Hardening Baseline

Script de hardening para servidores GNU/Linux basado en **CIS Benchmarks** + **25 años de experiencia en producción real 24/7**.

## Características

- **Idempotente**: Ejecutable múltiples veces sin efectos secundarios
- **Dos modos**: `--audit` (solo revisa) y `--apply` (aplica cambios con confirmación)
- **Backup automático**: Crea backup completo antes de cualquier cambio
- **Logging completo**: Todo queda registrado en `/var/log/linux-hardening-*.log`
- **Rollback fácil**: Restaura desde `$BACKUP_DIR` si algo falla
- **Multi-distro**: RHEL/Fedora/CentOS/Rocky/Alma, Debian/Ubuntu, openSUSE

## Módulos incluidos

| Módulo | Descripción |
|--------|-------------|
| **SSH** | Root login off, solo keys, cipher suites modernos, timeouts, banner |
| **Kernel (sysctl)** | Network hardening, ASLR, ptrace restrict, kexec disable, martians logging |
| **Filesystem** | noexec/nosuid/nodev en /tmp,/var/tmp,/dev/shm, sticky bits, módulos FS innecesarios |
| **Paquetes** | Auto-updates seguridad, remove servicios innecesarios (telnet, rsh, tftp, etc.) |
| **Auditd** | Reglas CIS: identity, privileged commands, file access, kernel modules, mount, perm_mod |
| **Logging** | Rsyslog permisos 640, rate limiting, timestamp RFC3339, logrotate 30 días comprimido |
| **Fail2ban** | SSH, recidive, nginx, apache, Zimbra, Postfix, Dovecot |
| **Usuarios** | PASS_MAX_DAYS 90, PAM pwquality (minlen=14, complejidad), umask 027, lock inactivos 30d |
| **Sudo** | Logfile, log_input/output, timestamp_timeout=5, requiretty, no NOPASSWD |
| **Firewall** | Firewalld (drop zone) o nftables baseline (SSH rate-limited, HTTP/HTTPS, ICMP) |
| **Docker** | userns-remap, no-new-privileges, seccomp profile custom, log rotation, live-restore |
| **Servicios** | Disable avahi, cups, dhcpd, nfs, rpcbind, named, vsftpd, snmpd, telnet, tftp, xinetd |

## Uso

```bash
# Solo auditoría (recomendado primero)
sudo ./linux-hardening.sh --audit

# Aplicar hardening (requiere confirmación 'SI')
sudo ./linux-hardening.sh --apply

# Ver ayuda
./linux-hardening.sh --help
```

## Requisitos

- Linux con systemd
- Root/sudo
- Bash 4+

## Logs y Backup

- **Log**: `/var/log/linux-hardening-YYYYMMDD-HHMMSS.log`
- **Backup**: `/root/hardening-backup-YYYYMMDD-HHMMSS/`

## Restaurar backup

```bash
# Si algo falla tras --apply
BACKUP_DIR="/root/hardening-backup-20241215-103000"
cp -rp $BACKUP_DIR/ssh/* /etc/ssh/
cp -rp $BACKUP_DIR/pam.d/* /etc/pam.d/
cp -rp $BACKUP_DIR/audit/* /etc/audit/
cp $BACKUP_DIR/sshd_config /etc/ssh/
cp $BACKUP_DIR/sysctl.conf /etc/sysctl.d/99-hardening.conf
# ... etc
systemctl restart sshd auditd rsyslog fail2ban
```

## Advertencias

1. **Prueba en staging primero** - Nunca apliques directo en producción sin testear
2. **Verifica SSH** - Tras `--apply`, **abre otra terminal y prueba login** antes de cerrar la actual
3. **Kernel params** - Requieren reboot para efecto completo
4. **Firewall** - Asegúrate de permitir tus IPs de gestión antes de aplicar

## Autor

**Devin Richard Conde Mancilla**  
Analista de Infraestructura y Seguridad Informática | SYSADMIN  
25+ años experiencia | La Paz, Bolivia  
🌐 https://www.devinconde.com  
💼 https://www.linkedin.com/in/devin-conde-mancilla-21038315  
📧 info@devinconde.com