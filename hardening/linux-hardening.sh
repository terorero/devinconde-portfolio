#!/bin/bash
# =============================================================================
# Linux Hardening Baseline - CIS Benchmark + 25 años experiencia real
# Autor: Devin Richard Conde Mancilla
# Web: https://www.devinconde.com
# LinkedIn: https://www.linkedin.com/in/devin-conde-mancilla-21038315
#
# Uso: sudo ./linux-hardening.sh [--audit|--apply|--help]
#   --audit  : Solo auditoría, no aplica cambios (default)
#   --apply  : Aplica hardening (requiere confirmación)
#   --help   : Muestra esta ayuda
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/linux-hardening-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/root/hardening-backup-$(date +%Y%m%d-%H%M%S)"
MODE="audit"  # audit | apply

# Funciones de logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARN:${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $*" | tee -a "$LOG_FILE"
}

# Banner
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    LINUX HARDENING BASELINE v1.0                            ║
║              CIS Benchmark + Experiencia Real 25 Años                       ║
║                        Devin Richard Conde Mancilla                         ║
║                         https://www.devinconde.com                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Verificar root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

# Crear backup de archivos críticos
create_backup() {
    mkdir -p "$BACKUP_DIR"
    info "Creando backup en $BACKUP_DIR"
    
    local files=(
        "/etc/ssh/sshd_config"
        "/etc/sudoers"
        "/etc/login.defs"
        "/etc/pam.d/system-auth"
        "/etc/pam.d/password-auth"
        "/etc/sysctl.conf"
        "/etc/security/limits.conf"
        "/etc/fstab"
        "/etc/hosts.allow"
        "/etc/hosts.deny"
        "/etc/audit/rules.d/audit.rules"
        "/etc/fail2ban/jail.local"
        "/etc/rsyslog.conf"
        "/etc/logrotate.conf"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            cp -p "$file" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    
    # Backup de directorios completos
    cp -rp /etc/ssh "$BACKUP_DIR/ssh" 2>/dev/null || true
    cp -rp /etc/pam.d "$BACKUP_DIR/pam.d" 2>/dev/null || true
    cp -rp /etc/audit "$BACKUP_DIR/audit" 2>/dev/null || true
    cp -rp /etc/fail2ban "$BACKUP_DIR/fail2ban" 2>/dev/null || true
    
    log "Backup completado en $BACKUP_DIR"
}

# =============================================================================
# 1. SSH HARDENING
# =============================================================================
harden_ssh() {
    info "=== SSH HARDENING ==="
    
    local sshd_config="/etc/ssh/sshd_config"
    local changes=0
    
    if [[ "$MODE" == "apply" ]]; then
        # Configuraciones de hardening SSH
        declare -A ssh_settings=(
            ["Protocol"]="2"
            ["PermitRootLogin"]="no"
            ["PubkeyAuthentication"]="yes"
            ["PasswordAuthentication"]="no"
            ["PermitEmptyPasswords"]="no"
            ["ChallengeResponseAuthentication"]="no"
            ["UsePAM"]="yes"
            ["X11Forwarding"]="no"
            ["AllowTcpForwarding"]="no"
            ["AllowAgentForwarding"]="no"
            ["PermitTunnel"]="no"
            ["DebianBanner"]="no"
            ["PrintMotd"]="no"
            ["ClientAliveInterval"]="300"
            ["ClientAliveCountMax"]="2"
            ["MaxAuthTries"]="3"
            ["MaxSessions"]="2"
            ["LoginGraceTime"]="30"
            ["Banner"]="/etc/issue.net"
            ["Ciphers"]="chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"
            ["MACs"]="hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com"
            ["KexAlgorithms"]="curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256"
        )
        
        for key in "${!ssh_settings[@]}"; do
            value="${ssh_settings[$key]}"
            if grep -q "^#*${key}[[:space:]]" "$sshd_config"; then
                sed -i "s/^#*${key}[[:space:]].*/${key} ${value}/" "$sshd_config"
            else
                echo "${key} ${value}" >> "$sshd_config"
            fi
            ((changes++))
        done
        
        # Permitir solo usuarios específicos (configurar según entorno)
        # AllowUsers admin usuario1 usuario2
        
        log "SSH hardening aplicado ($changes cambios)"
        systemctl reload sshd 2>/dev/null || service ssh reload 2>/dev/null || true
    else
        # Modo auditoría
        local checks=(
            "PermitRootLogin no"
            "PubkeyAuthentication yes"
            "PasswordAuthentication no"
            "PermitEmptyPasswords no"
            "ChallengeResponseAuthentication no"
            "MaxAuthTries 3"
            "ClientAliveInterval 300"
            "ClientAliveCountMax 2"
            "LoginGraceTime 30"
        )
        
        for check in "${checks[@]}"; do
            local key=$(echo "$check" | awk '{print $1}')
            local expected=$(echo "$check" | awk '{print $2}')
            local actual=$(grep -i "^${key}[[:space:]]" "$sshd_config" | awk '{print $2}' | head -1)
            
            if [[ "$actual" == "$expected" ]]; then
                log "  ✓ $key = $actual"
            else
                warn "  ✗ $key = ${actual:-'NO CONFIGURADO'} (esperado: $expected)"
            fi
        done
    fi
}

# =============================================================================
# 2. KERNEL PARAMETERS (SYSCTL)
# =============================================================================
harden_kernel() {
    info "=== KERNEL HARDENING (SYSCTL) ==="
    
    local sysctl_file="/etc/sysctl.d/99-hardening.conf"
    local changes=0
    
    declare -A kernel_params=(
        # Network hardening
        ["net.ipv4.ip_forward"]="0"
        ["net.ipv4.conf.all.send_redirects"]="0"
        ["net.ipv4.conf.default.send_redirects"]="0"
        ["net.ipv4.conf.all.accept_redirects"]="0"
        ["net.ipv4.conf.default.accept_redirects"]="0"
        ["net.ipv4.conf.all.accept_source_route"]="0"
        ["net.ipv4.conf.default.accept_source_route"]="0"
        ["net.ipv4.conf.all.log_martians"]="1"
        ["net.ipv4.conf.default.log_martians"]="1"
        ["net.ipv4.icmp_echo_ignore_broadcasts"]="1"
        ["net.ipv4.icmp_ignore_bogus_error_responses"]="1"
        ["net.ipv4.tcp_syncookies"]="1"
        ["net.ipv4.tcp_max_syn_backlog"]="2048"
        ["net.ipv4.tcp_synack_retries"]="2"
        ["net.ipv4.tcp_syn_retries"]="5"
        ["net.ipv6.conf.all.accept_redirects"]="0"
        ["net.ipv6.conf.default.accept_redirects"]="0"
        ["net.ipv6.conf.all.accept_source_route"]="0"
        ["net.ipv6.conf.default.accept_source_route"]="0"
        
        # Kernel hardening
        ["kernel.exec-shield"]="1"
        ["kernel.randomize_va_space"]="2"
        ["kernel.kptr_restrict"]="2"
        ["kernel.dmesg_restrict"]="1"
        ["kernel.perf_event_paranoid"]="3"
        ["kernel.yama.ptrace_scope"]="1"
        ["kernel.sysrq"]="0"
        ["kernel.kexec_load_disabled"]="1"
        
        # Filesystem hardening
        ["fs.suid_dumpable"]="0"
        ["fs.protected_hardlinks"]="1"
        ["fs.protected_symlinks"]="1"
        ["fs.protected_fifos"]="2"
        ["fs.protected_regular"]="2"
    )
    
    if [[ "$MODE" == "apply" ]]; then
        cat > "$sysctl_file" << 'EOF'
# Linux Kernel Hardening - CIS Benchmark + Custom
# Generado por linux-hardening.sh - Devin Conde Mancilla
# https://www.devinconde.com

EOF
        for param in "${!kernel_params[@]}"; do
            echo "${param} = ${kernel_params[$param]}" >> "$sysctl_file"
            sysctl -w "${param}=${kernel_params[$param]}" 2>/dev/null || true
            ((changes++))
        done
        
        sysctl --system 2>/dev/null || true
        log "Kernel hardening aplicado ($changes parámetros)"
    else
        for param in "${!kernel_params[@]}"; do
            expected="${kernel_params[$param]}"
            actual=$(sysctl -n "$param" 2>/dev/null || echo "N/A")
            if [[ "$actual" == "$expected" ]]; then
                log "  ✓ $param = $actual"
            else
                warn "  ✗ $param = $actual (esperado: $expected)"
            fi
        done
    fi
}

# =============================================================================
# 3. FILESYSTEM HARDENING
# =============================================================================
harden_filesystem() {
    info "=== FILESYSTEM HARDENING ==="
    
    if [[ "$MODE" == "apply" ]]; then
        # Verificar opciones de montaje en /etc/fstab
        local mounts_to_check=(
            "/tmp:nodev,nosuid,noexec"
            "/var/tmp:nodev,nosuid,noexec"
            "/dev/shm:nodev,nosuid,noexec"
            "/home:nodev,nosuid"
            "/var:nodev"
        )
        
        for mount_spec in "${mounts_to_check[@]}"; do
            local mount_point=$(echo "$mount_spec" | cut -d: -f1)
            local options=$(echo "$mount_spec" | cut -d: -f2)
            
            if mountpoint -q "$mount_point" 2>/dev/null; then
                # Remontar con opciones seguras
                mount -o remount,$options "$mount_point" 2>/dev/null && \
                    log "  Remontado $mount_point con $options" || \
                    warn "  No se pudo remontar $mount_point (requiere entrada en fstab)"
            fi
        done
        
        # Sticky bit en directorios world-writable
        find / -xdev -type d -perm -0002 -not -perm -1000 2>/dev/null | while read dir; do
            chmod +t "$dir" 2>/dev/null && log "  Sticky bit añadido a $dir"
        done
        
        # Deshabilitar filesystem poco comunes
        local filesystems=("cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "squashfs" "udf")
        for fs in "${filesystems[@]}"; do
            echo "install $fs /bin/true" > "/etc/modprobe.d/${fs}.conf"
        done
        
        log "Filesystem hardening aplicado"
    else
        # Auditoría de montajes
        mount | grep -E "(tmp|shm|home|var)" | while read line; do
            info "  Montaje: $line"
        done
        
        # Verificar sticky bits
        find / -xdev -type d -perm -0002 -not -perm -1000 2>/dev/null | head -10 | while read dir; do
            warn "  Sin sticky bit: $dir"
        done
    fi
}

# =============================================================================
# 4. PACKAGE MANAGEMENT & UPDATES
# =============================================================================
harden_packages() {
    info "=== PACKAGE MANAGEMENT ==="
    
    if [[ "$MODE" == "apply" ]]; then
        # Configurar actualizaciones automáticas de seguridad
        if command -v dnf &>/dev/null; then
            # RHEL/Fedora/CentOS/Rocky/Alma
            dnf install -y dnf-automatic 2>/dev/null || true
            sed -i 's/^apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf 2>/dev/null || true
            sed -i 's/^upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf 2>/dev/null || true
            systemctl enable --now dnf-automatic.timer 2>/dev/null || true
        elif command -v apt &>/dev/null; then
            # Debian/Ubuntu
            apt-get install -y unattended-upgrades 2>/dev/null || true
            cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
            systemctl enable --now unattended-upgrades 2>/dev/null || true
        elif command -v zypper &>/dev/null; then
            # openSUSE
            zypper install -y yast2-online-update-configuration 2>/dev/null || true
        fi
        
        # Eliminar paquetes innecesarios comunes
        local unnecessary=("telnet" "rsh" "ypbind" "tftp" "tftp-server" "talk" "talk-server" "xinetd" "chargen-dgram" "chargen-stream" "daytime-dgram" "daytime-stream" "echo-dgram" "echo-stream" "tcpmux-server")
        for pkg in "${unnecessary[@]}"; do
            if rpm -q "$pkg" &>/dev/null; then
                rpm -e "$pkg" 2>/dev/null && log "  Eliminado: $pkg"
            elif dpkg -l "$pkg" &>/dev/null; then
                apt-get remove -y "$pkg" 2>/dev/null && log "  Eliminado: $pkg"
            fi
        done
        
        log "Gestión de paquetes configurada"
    else
        # Verificar actualizaciones pendientes
        if command -v dnf &>/dev/null; then
            dnf check-update --security 2>/dev/null | head -20
        elif command -v apt &>/dev/null; then
            apt list --upgradable 2>/dev/null | grep -i security | head -20
        fi
    fi
}

# =============================================================================
# 5. AUDITING (AUDITD)
# =============================================================================
harden_auditing() {
    info "=== AUDITD CONFIGURATION ==="
    
    local audit_rules="/etc/audit/rules.d/audit.rules"
    
    if [[ "$MODE" == "apply" ]]; then
        cat > "$audit_rules" << 'EOF'
# Auditd Rules - CIS Benchmark + Custom
# Generado por linux-hardening.sh - Devin Conde Mancilla

# Eliminar reglas previas
-D

# Buffer size
-b 8192

# Failure mode
-f 1

# ===== SYSTEM CALLS =====
# Modificaciones de hora
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S clock_settime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change

# Cambios de identidad
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale

# Cambios de red
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale

# Cambios en /etc/passwd, /etc/shadow, /etc/group, /etc/gshadow
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Cambios en configuración de red
-w /etc/hosts -p wa -k system-locale
-w /etc/hostname -p wa -k system-locale
-w /etc/resolv.conf -p wa -k system-locale

# Cambios en configuración SSH
-w /etc/ssh/sshd_config -p wa -k sshd-config

# Cambios en sudoers
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# Cambios en firewall
-w /etc/firewalld/ -p wa -k firewall
-w /etc/iptables/ -p wa -k firewall
-w /etc/nftables/ -p wa -k firewall

# Ejecución de comandos privilegiados
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/su -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged

# Montaje/desmontaje
-a always,exit -F arch=b64 -S mount -S umount2 -k mount
-a always,exit -F arch=b32 -S mount -S umount2 -k mount

# Cambios en permisos
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod

# Accesos no autorizados
-a always,exit -F arch=b64 -S open -S openat -S open_by_handle_at -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S open -S openat -S open_by_handle_at -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S open -S openat -S open_by_handle_at -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S open -S openat -S open_by_handle_at -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access

# Módulos de kernel
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules

# Hacer la configuración inmutable (requiere reboot para cambiar)
-e 2
EOF
        
        # Reiniciar auditd
        systemctl restart auditd 2>/dev/null || service auditd restart 2>/dev/null || true
        log "Auditd configurado y reiniciado"
    else
        if [[ -f "$audit_rules" ]]; then
            log "  ✓ Reglas auditd existen"
            auditctl -l 2>/dev/null | head -20
        else
            warn "  ✗ No hay reglas auditd configuradas"
        fi
    fi
}

# =============================================================================
# 6. LOGGING (RSYSLOG + LOGROTATE)
# =============================================================================
harden_logging() {
    info "=== LOGGING HARDENING ==="
    
    if [[ "$MODE" == "apply" ]]; then
        # Rsyslog: logging remoto + local
        cat > /etc/rsyslog.d/99-hardening.conf << 'EOF'
# Rsyslog Hardening - Devin Conde Mancilla

# Permisos de archivos de log
$FileCreateMode 0640
$DirCreateMode 0750
$FileOwner root
$FileGroup adm

# Logging remoto (configurar IP de servidor de logs)
# *.* @logserver.example.com:514

# Rate limiting
$SystemLogRateLimitInterval 5
$SystemLogRateLimitBurst 200

# Formato timestamp preciso
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$template Precise,"%timegenerated:::date-rfc3339% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n"
$ActionFileDefaultTemplate Precise
EOF
        
        # Logrotate hardening
        cat > /etc/logrotate.d/hardening << 'EOF'
# Logrotate Hardening - Devin Conde Mancilla

/var/log/*log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate > /dev/null 2>&1 || true
    endscript
}

/var/log/audit/*log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0600 root root
    sharedscripts
    postrotate
        /bin/kill -HUP $(cat /var/run/auditd.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
EOF
        
        systemctl restart rsyslog 2>/dev/null || service rsyslog restart 2>/dev/null || true
        log "Logging hardening aplicado"
    else
        # Verificar configuración
        if grep -q "FileCreateMode 0640" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
            log "  ✓ Permisos de log configurados"
        else
            warn "  ✗ Permisos de log no restringidos"
        fi
    fi
}

# =============================================================================
# 7. FAIL2BAN
# =============================================================================
harden_fail2ban() {
    info "=== FAIL2BAN CONFIGURATION ==="
    
    if [[ "$MODE" == "apply" ]]; then
        # Instalar fail2ban si no está
        if command -v dnf &>/dev/null; then
            dnf install -y fail2ban 2>/dev/null || true
        elif command -v apt &>/dev/null; then
            apt-get install -y fail2ban 2>/dev/null || true
        fi
        
        cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Fail2Ban Hardening - Devin Conde Mancilla
ignoreip = 127.0.0.1/8 ::1
bantime  = 3600
findtime = 600
maxretry = 3
backend = systemd
banaction = iptables-multiport
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
bantime = 3600

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = %(sshd_log)s
maxretry = 3

[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
bantime = 86400
findtime = 86400
maxretry = 5

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-badbots]
enabled = true
filter = nginx-badbots
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2

[apache-auth]
enabled = true
filter = apache-auth
port = http,https
logpath = /var/log/apache2/error.log

[zimbra-auth]
enabled = true
filter = zimbra-auth
port = 7071,443,993,995,25,465,587
logpath = /var/log/zimbra.log
maxretry = 5

[postfix-sasl]
enabled = true
filter = postfix-sasl
port = smtp,465,587
logpath = /var/log/mail.log
maxretry = 3

[dovecot]
enabled = true
filter = dovecot
port = pop3,pop3s,imap,imaps
logpath = /var/log/mail.log
maxretry = 3
EOF
        
        systemctl enable --now fail2ban 2>/dev/null || service fail2ban restart 2>/dev/null || true
        log "Fail2ban configurado y activado"
    else
        if systemctl is-active fail2ban &>/dev/null; then
            log "  ✓ Fail2ban activo"
            fail2ban-client status 2>/dev/null | head -10
        else
            warn "  ✗ Fail2ban no está activo"
        fi
    fi
}

# =============================================================================
# 8. USER ACCOUNTS & PASSWORD POLICIES
# =============================================================================
harden_users() {
    info "=== USER ACCOUNTS & PASSWORD POLICIES ==="
    
    if [[ "$MODE" == "apply" ]]; then
        # Password policies en /etc/login.defs
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
        sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
        sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
        sed -i 's/^FAIL_DELAY.*/FAIL_DELAY      4/' /etc/login.defs
        
        # PAM password quality
        if [[ -f /etc/pam.d/system-auth ]]; then
            sed -i '/pam_pwquality.so/s/.*/password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/' /etc/pam.d/system-auth
        fi
        if [[ -f /etc/pam.d/password-auth ]]; then
            sed -i '/pam_pwquality.so/s/.*/password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/' /etc/pam.d/password-auth
        fi
        
        # Lock cuentas inactivas
        useradd -D -f 30 2>/dev/null || true
        
        # Umask restrictivo por defecto
        echo "umask 027" >> /etc/profile
        echo "umask 027" >> /etc/bashrc
        
        # Deshabilitar cuentas del sistema sin shell válido
        while IFS=: read -r user _ _ _ _ _ shell; do
            if [[ "$shell" == "/sbin/nologin" || "$shell" == "/bin/false" || "$shell" == "/usr/sbin/nologin" ]]; then
                usermod -L "$user" 2>/dev/null || true
                usermod -s /sbin/nologin "$user" 2>/dev/null || true
            fi
        done < /etc/passwd
        
        log "Políticas de usuario aplicadas"
    else
        # Auditoría
        grep -E "^PASS_MAX_DAYS|^PASS_MIN_DAYS|^PASS_WARN_AGE" /etc/login.defs | while read line; do
            info "  $line"
        done
        
        # Verificar usuarios con UID 0 (debe ser solo root)
        awk -F: '$3 == 0 {print $1}' /etc/passwd | while read user; do
            if [[ "$user" != "root" ]]; then
                warn "  Usuario con UID 0: $user"
            fi
        done
        
        # Usuarios sin contraseña
        awk -F: '$2 == "" {print $1}' /etc/shadow 2>/dev/null | while read user; do
            warn "  Usuario sin contraseña: $user"
        done
    fi
}

# =============================================================================
# 9. SUDO HARDENING
# =============================================================================
harden_sudo() {
    info "=== SUDO HARDENING ==="
    
    if [[ "$MODE" == "apply" ]]; then
        # Configurar sudoers de forma segura
        cat > /etc/sudoers.d/hardening << 'EOF'
# Sudo Hardening - Devin Conde Mancilla
# Solo usuarios en grupo wheel/admin pueden usar sudo
%wheel ALL=(ALL) ALL
%admin ALL=(ALL) ALL

# Defaults seguros
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults    logfile="/var/log/sudo.log"
Defaults    log_input, log_output
Defaults    requiretty
Defaults    timestamp_timeout=5
Defaults    passwd_tries=3
Defaults    badpass_message="Acceso denegado. Intento registrado."
Defaults    insults
Defaults    !visiblepw
Defaults    !env_reset
Defaults    env_keep += "LANG LANGUAGE LC_*"

# No permitir NOPASSWD
# %wheel ALL=(ALL) NOPASSWD: ALL  # COMENTADO POR SEGURIDAD
EOF
        
        chmod 440 /etc/sudoers.d/hardening
        visudo -c 2>/dev/null && log "  Sudoers válido" || warn "  Sudoers tiene errores"
        log "Sudo hardening aplicado"
    else
        # Verificar configuración
        if grep -q "logfile" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
            log "  ✓ Logging de sudo configurado"
        else
            warn "  ✗ Sin logging de sudo"
        fi
        
        if grep -q "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
            warn "  ✗ NOPASSWD detectado en sudoers"
        else
            log "  ✓ Sin NOPASSWD"
        fi
    fi
}

# =============================================================================
# 10. FIREWALL BASELINE (NFTABLES/IPTABLES)
# =============================================================================
harden_firewall() {
    info "=== FIREWALL BASELINE ==="
    
    if [[ "$MODE" == "apply" ]]; then
        # Usar firewalld si está disponible, si no nftables/iptables
        if systemctl is-active firewalld &>/dev/null; then
            # Firewalld zones
            firewall-cmd --set-default-zone=drop 2>/dev/null || true
            firewall-cmd --zone=drop --add-interface=eth0 --permanent 2>/dev/null || true
            firewall-cmd --zone=public --add-service=ssh --permanent 2>/dev/null || true
            firewall-cmd --zone=public --add-service=http --permanent 2>/dev/null || true
            firewall-cmd --zone=public --add-service=https --permanent 2>/dev/null || true
            firewall-cmd --reload 2>/dev/null || true
        elif command -v nft &>/dev/null; then
            # Nftables baseline
            cat > /etc/nftables.conf << 'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        # Loopback
        iif lo accept
        
        # Established/related
        ct state established,related accept
        
        # ICMP
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
        
        # SSH (rate limited)
        tcp dport 22 ct state new limit rate 3/minute accept
        
        # HTTP/HTTPS
        tcp dport {80, 443} accept
        
        # Log dropped
        log prefix "DROPPED: " flags all
    }
    
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF
            nft -f /etc/nftables.conf 2>/dev/null || true
            systemctl enable --now nftables 2>/dev/null || true
        fi
        
        log "Firewall baseline aplicado"
    else
        # Verificar estado
        if systemctl is-active firewalld &>/dev/null; then
            log "  ✓ Firewalld activo"
            firewall-cmd --list-all 2>/dev/null | head -20
        elif systemctl is-active nftables &>/dev/null; then
            log "  ✓ Nftables activo"
            nft list ruleset 2>/dev/null | head -30
        elif command -v iptables &>/dev/null && iptables -L -n 2>/dev/null | grep -q "Chain"; then
            log "  ✓ Iptables tiene reglas"
            iptables -L -n 2>/dev/null | head -20
        else
            warn "  ✗ No hay firewall activo"
        fi
    fi
}

# =============================================================================
# 11. DOCKER HOST HARDENING (si Docker está presente)
# =============================================================================
harden_docker() {
    info "=== DOCKER HOST HARDENING ==="
    
    if ! command -v docker &>/dev/null; then
        info "  Docker no instalado, omitiendo"
        return
    fi
    
    if [[ "$MODE" == "apply" ]]; then
        # Daemon.json hardening
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << 'EOF'
{
  "icc": false,
  "userns-remap": "default",
  "live-restore": true,
  "no-new-privileges": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 64000
    }
  },
  "seccomp-profile": "/etc/docker/seccomp-profile.json"
}
EOF
        
        # Seccomp profile personalizado
        cat > /etc/docker/seccomp-profile.json << 'EOF'
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_X86", "SCMP_ARCH_X32"],
  "syscalls": [
    {"names": ["accept", "accept4", "access", "arch_prctl", "bind", "brk", "capget", "capset", "chdir", "chmod", "chown", "clock_gettime", "close", "connect", "copy_file_range", "dup", "dup2", "dup3", "epoll_create", "epoll_create1", "epoll_ctl", "epoll_pwait", "epoll_wait", "eventfd", "eventfd2", "execve", "exit", "exit_group", "faccessat", "fadvise64", "fallocate", "fchdir", "fchmod", "fchmodat", "fchown", "fchownat", "fcntl", "fdatasync", "fgetxattr", "flistxattr", "flock", "fork", "fremovexattr", "fsetxattr", "fstat", "fstatfs", "fsync", "ftruncate", "futex", "getcwd", "getdents", "getdents64", "getegid", "geteuid", "getgid", "getgroups", "getpeername", "getpid", "getppid", "getpriority", "getrandom", "getrlimit", "getrusage", "getsockname", "getsockopt", "gettid", "gettimeofday", "getuid", "getxattr", "inotify_add_watch", "inotify_init", "inotify_init1", "inotify_rm_watch", "io_cancel", "io_destroy", "io_getevents", "io_setup", "io_submit", "ioctl", "ipc", "kill", "lchown", "lgetxattr", "link", "linkat", "listen", "listxattr", "llistxattr", "lseek", "lsetxattr", "lstat", "madvise", "memfd_create", "mincore", "mkdir", "mkdirat", "mknod", "mknodat", "mlock", "mlock2", "mlockall", "mmap", "mprotect", "mq_getsetattr", "mq_notify", "mq_open", "mq_timedreceive", "mq_timedsend", "mq_unlink", "mremap", "msgctl", "msgget", "msgrcv", "msgsnd", "munlock", "munlockall", "munmap", "nanosleep", "newfstatat", "open", "openat", "pause", "pipe", "pipe2", "poll", "ppoll", "prctl", "pread", "preadv", "preadv2", "prlimit64", "pselect6", "pwrite", "pwritev", "pwritev2", "read", "readahead", "readlink", "readlinkat", "readv", "recvfrom", "recvmmsg", "recvmsg", "removexattr", "rename", "renameat", "restart_syscall", "rmdir", "rt_sigaction", "rt_sigprocmask", "rt_sigqueueinfo", "rt_sigreturn", "rt_sigsuspend", "rt_sigtimedwait", "sched_getaffinity", "sched_getparam", "sched_get_priority_max", "sched_get_priority_min", "sched_getscheduler", "sched_rr_get_interval", "sched_setaffinity", "sched_setparam", "sched_setscheduler", "sched_yield", "select", "semctl", "semget", "semop", "semtimedop", "sendfile", "sendmmsg", "sendmsg", "sendto", "setfsgid", "setgid", "setpgid", "setpriority", "setregid", "setresgid", "setresuid", "setreuid", "setrlimit", "setsid", "setsockopt", "settid_address", "setuid", "setxattr", "shmat", "shmctl", "shmdt", "shmget", "shutdown", "sigaltstack", "signalfd", "signalfd4", "socket", "socketpair", "splice", "stat", "statfs", "statx", "symlink", "symlinkat", "sync", "sync_file_range", "syncfs", "sysinfo", "tee", "tgkill", "time", "timer_create", "timer_delete", "timer_getoverrun", "timer_gettime", "timer_settime", "times", "tkill", "truncate", "ugetrlimit", "umask", "uname", "unlink", "unlinkat", "utime", "utimensat", "vfork", "vmsplice", "wait4", "waitid", "waitpid", "write", "writev"]}]
EOF
        
        systemctl restart docker 2>/dev/null || service docker restart 2>/dev/null || true
        log "Docker hardening aplicado"
    else
        # Auditoría
        if [[ -f /etc/docker/daemon.json ]]; then
            log "  ✓ daemon.json existe"
            cat /etc/docker/daemon.json | jq . 2>/dev/null || cat /etc/docker/daemon.json
        else
            warn "  ✗ Sin daemon.json"
        fi
        
        # Verificar userns-remap
        if docker info 2>/dev/null | grep -q "userns-remap"; then
            log "  ✓ userns-remap habilitado"
        else
            warn "  ✗ userns-remap no habilitado"
        fi
    fi
}

# =============================================================================
# 12. SERVICES HARDENING
# =============================================================================
harden_services() {
    info "=== SERVICES HARDENING ==="
    
    # Servicios a deshabilitar si no se usan
    local services_to_disable=(
        "avahi-daemon"
        "cups"
        "dhcpd"
        "slapd"
        "nfs-server"
        "rpcbind"
        "named"
        "vsftpd"
        "httpd"
        "nginx"
        "dovecot"
        "postfix"
        "squid"
        "snmpd"
        "telnet"
        "tftp"
        "xinetd"
    )
    
    if [[ "$MODE" == "apply" ]]; then
        for svc in "${services_to_disable[@]}"; do
            if systemctl is-enabled "$svc" &>/dev/null; then
                systemctl disable --now "$svc" 2>/dev/null && log "  Deshabilitado: $svc" || true
            fi
        done
        
        # Habilitar servicios de seguridad
        local services_to_enable=("auditd" "fail2ban" "rsyslog" "chronyd" "systemd-timesyncd")
        for svc in "${services_to_enable[@]}"; do
            systemctl enable --now "$svc" 2>/dev/null || true
        done
        
        log "Servicios hardening aplicado"
    else
        for svc in "${services_to_disable[@]}"; do
            if systemctl is-active "$svc" &>/dev/null; then
                warn "  Servicio activo (revisar si necesario): $svc"
            fi
        done
    fi
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================
main() {
    show_banner
    check_root
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --apply)
                MODE="apply"
                shift
                ;;
            --audit)
                MODE="audit"
                shift
                ;;
            --help)
                cat << EOF
Uso: $0 [--audit|--apply|--help]

  --audit   Solo auditoría, no aplica cambios (default)
  --apply   Aplica hardening (requiere confirmación)
  --help    Muestra esta ayuda

Ejemplos:
  $0 --audit    # Ver qué cambiaría
  $0 --apply    # Aplicar hardening (con confirmación)
EOF
                exit 0
                ;;
            *)
                error "Opción desconocida: $1"
                exit 1
                ;;
        esac
    done
    
    if [[ "$MODE" == "apply" ]]; then
        warn "MODO APLICAR - Se modificarán archivos del sistema"
        read -p "¿Continuar? (escribe 'SI' para confirmar): " confirm
        if [[ "$confirm" != "SI" ]]; then
            log "Cancelado por usuario"
            exit 0
        fi
        create_backup
    fi
    
    log "Iniciando hardening en modo: $MODE"
    log "Log guardado en: $LOG_FILE"
    
    # Ejecutar todos los módulos
    harden_ssh
    harden_kernel
    harden_filesystem
    harden_packages
    harden_auditing
    harden_logging
    harden_fail2ban
    harden_users
    harden_sudo
    harden_firewall
    harden_docker
    harden_services
    
    log "=== HARDENING COMPLETADO ==="
    log "Log completo: $LOG_FILE"
    
    if [[ "$MODE" == "apply" ]]; then
        log "Backup guardado en: $BACKUP_DIR"
        warn "IMPORTANTE: Reinicia el sistema para aplicar todos los cambios de kernel"
        warn "Verifica conectividad SSH ANTES de cerrar esta sesión"
    fi
}

# Ejecutar
main "$@"