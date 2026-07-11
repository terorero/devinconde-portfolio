#!/bin/bash
# =============================================================================
# Borg Backup Script - Incremental, Encrypted, Deduplicated
# Devin Conde Mancilla - Production use at La Razón (200+ users, 5TB+ data)
# https://www.devinconde.com
# =============================================================================

set -euo pipefail

# Configuration
REPO="${BORG_REPO:-ssh://borg@backup.example.com:/volume1/borg-backups/la-razon}"
EXCLUDES_FILE="${BORG_EXCLUDES:-/etc/borg/excludes.lst}"
PASSPHRASE_FILE="${BORG_PASSPHRASE_FILE:-/etc/borg/passphrase}"
LOG_FILE="/var/log/borg-backup.log"
RETENTION="${BORG_RETENTION:---keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 3}"
COMPRESSION="${BORG_COMPRESSION:-lz4}"
CHECK_REPO="${BORG_CHECK_REPO:-true}"
RESTORE_TEST="${BORG_RESTORE_TEST:-true}"

# Export passphrase
if [[ -f "$PASSPHRASE_FILE" ]]; then
    export BORG_PASSPHRASE="$(cat "$PASSPHRASE_FILE")"
else
    echo "ERROR: Passphrase file not found: $PASSPHRASE_FILE" >&2
    exit 1
fi

export BORG_REPO="$REPO"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# Pre-backup checks
pre_checks() {
    log "=== PRE-BACKUP CHECKS ==="
    
    # Check repository connectivity
    if ! borg list "$REPO" --last 1 &>/dev/null; then
        error "Cannot connect to repository: $REPO"
        return 1
    fi
    log "Repository connectivity: OK"
    
    # Check repository integrity (optional, can be slow)
    if [[ "$CHECK_REPO" == "true" ]]; then
        log "Checking repository integrity..."
        if borg check -v "$REPO" 2>&1 | tee -a "$LOG_FILE"; then
            log "Repository integrity check: PASSED"
        else
            error "Repository integrity check: FAILED"
            return 1
        fi
    fi
    
    # Check disk space on source
    local available=$(df / | tail -1 | awk '{print $4}')
    if [[ $available -lt 1048576 ]]; then  # Less than 1GB free
        warn "Low disk space on /: ${available}KB available"
    fi
    
    log "Pre-backup checks completed"
}

# Main backup function
run_backup() {
    log "=== STARTING BACKUP ==="
    log "Repository: $REPO"
    log "Excludes file: $EXCLUDES_FILE"
    log "Retention: $RETENTION"
    log "Compression: $COMPRESSION"
    
    local start_time=$(date +%s)
    local archive_name="$(hostname)-$(date +%Y-%m-%dT%H:%M:%S)"
    
    # Create the backup
    if borg create \
        --verbose \
        --stats \
        --compression "$COMPRESSION" \
        --exclude-from "$EXCLUDES_FILE" \
        --exclude-caches \
        --exclude-if-present .nobackup \
        --exclude-if-present .nobackup \
        --one-file-system \
        --filter AME \
        --list \
        --progress \
        "$REPO::$archive_name" \
        /etc \
        /home \
        /var/lib \
        /opt \
        /srv \
        /root \
        /usr/local \
        2>&1 | tee -a "$LOG_FILE"; then
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "Backup completed successfully in ${duration}s"
        log "Archive: $archive_name"
        
        # Get archive info
        borg info "$REPO::$archive_name" 2>&1 | tee -a "$LOG_FILE"
        
        return 0
    else
        local exit_code=$?
        error "Backup failed with exit code $exit_code"
        return $exit_code
    fi
}

# Prune old backups
prune_backups() {
    log "=== PRUNING OLD BACKUPS ==="
    log "Retention policy: $RETENTION"
    
    if borg prune \
        --verbose \
        --stats \
        --list \
        $RETENTION \
        "$REPO" \
        2>&1 | tee -a "$LOG_FILE"; then
        log "Pruning completed successfully"
        return 0
    else
        error "Pruning failed"
        return 1
    fi
}

# Compact repository (run monthly)
compact_repo() {
    if [[ $(date +%d) == "01" ]]; then
        log "=== COMPACTING REPOSITORY (monthly) ==="
        if borg compact "$REPO" 2>&1 | tee -a "$LOG_FILE"; then
            log "Repository compaction completed"
        else
            error "Repository compaction failed"
        fi
    else
        log "Skipping compaction (not 1st of month)"
    fi
}

# Verify backup integrity
verify_backup() {
    log "=== VERIFYING BACKUP ==="
    
    # List latest archives
    log "Recent archives:"
    borg list "$REPO" --last 5 2>&1 | tee -a "$LOG_FILE"
    
    # Quick check on latest archive
    local latest=$(borg list "$REPO" --last 1 --format '{archive}{NL}')
    if [[ -n "$latest" ]]; then
        log "Verifying latest archive: $latest"
        if borg extract -v "$REPO::$latest" --dry-run 2>&1 | tail -20 | tee -a "$LOG_FILE"; then
            log "Archive verification: PASSED"
        else
            error "Archive verification: FAILED"
            return 1
        fi
    fi
}

# Restore test (run monthly on first Monday)
restore_test() {
    if [[ "$RESTORE_TEST" == "true" ]] && [[ $(date +%u) == 1 ]] && [[ $(date +%d) -le 07 ]]; then
        log "=== MONTHLY RESTORE TEST ==="
        local test_dir="/tmp/borg-restore-test-$(date +%s)"
        mkdir -p "$test_dir"
        
        local latest=$(borg list "$REPO" --last 1 --format '{archive}{NL}')
        if [[ -n "$latest" ]]; then
            log "Testing restore of: $latest"
            if borg extract "$REPO::$latest" --path "$test_dir/etc/hostname" 2>&1 | tee -a "$LOG_FILE"; then
                if [[ -f "$test_dir/etc/hostname" ]]; then
                    log "Restore test: PASSED - File restored successfully"
                    cat "$test_dir/etc/hostname" | tee -a "$LOG_FILE"
                else
                    error "Restore test: FAILED - File not found after extraction"
                fi
            else
                error "Restore test: FAILED - Extraction failed"
            fi
        fi
        
        rm -rf "$test_dir"
    else
        log "Skipping restore test (not first Monday of month)"
    fi
}

# Post-backup notification
notify() {
    local status=$1
    local message=$2
    
    # Email notification (requires mailutils/ssmtp configured)
    if command -v mail &>/dev/null; then
        echo "$message" | mail -s "Borg Backup $status on $(hostname)" admin@example.com 2>/dev/null || true
    fi
    
    # Slack webhook (if configured)
    if [[ -n "${SLACK_WEBHOOK:-}" ]]; then
        local color="good"
        [[ "$status" == "FAILED" ]] && color="danger"
        [[ "$status" == "WARNING" ]] && color="warning"
        
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"attachments\":[{\"color\":\"$color\",\"title\":\"Borg Backup $status\",\"text\":\"$message\",\"footer\":\"$(hostname)\",\"ts\":$(date +%s)}]}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Main execution
main() {
    log "==========================================="
    log "Borg Backup Started on $(hostname)"
    log "==========================================="
    
    local overall_status=0
    local messages=()
    
    # Run all steps
    if pre_checks; then
        messages+=("✅ Pre-checks passed")
    else
        messages+=("❌ Pre-checks failed")
        overall_status=1
    fi
    
    if [[ $overall_status -eq 0 ]] && run_backup; then
        messages+=("✅ Backup completed")
    else
        messages+=("❌ Backup failed")
        overall_status=1
    fi
    
    if [[ $overall_status -eq 0 ]] && prune_backups; then
        messages+=("✅ Pruning completed")
    else
        messages+=("❌ Pruning failed")
        overall_status=1
    fi
    
    compact_repo
    
    if [[ $overall_status -eq 0 ]] && verify_backup; then
        messages+=("✅ Verification passed")
    else
        messages+=("❌ Verification failed")
        overall_status=1
    fi
    
    restore_test
    
    # Summary
    log "==========================================="
    log "BACKUP SUMMARY"
    log "==========================================="
    for msg in "${messages[@]}"; do
        log "  $msg"
    done
    
    local status="SUCCESS"
    [[ $overall_status -ne 0 ]] && status="FAILED"
    log "Overall status: $status"
    log "==========================================="
    
    notify "$status" "$(printf '%s\n' "${messages[@]}")"
    
    exit $overall_status
}

# Handle signals
trap 'error "Backup interrupted by signal"; notify "INTERRUPTED" "Backup interrupted on $(hostname)"; exit 130' INT TERM

# Run main
main "$@"