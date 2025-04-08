#!/bin/bash

# SSH Maintenance Script for Ubuntu and CentOS

# === Configurable Variables ===
REQUIRED_USERS=("user1" "user2")
KEY_DIR="/etc/ssh/authorized_keys_backup"
LOG_FILE="/var/log/ssh_maintenance.log"

log() {
    echo "$(date '+%F %T') - $1" | tee -a "$LOG_FILE"
}

check_ssh_config() {
    log "Checking sshd configuration..."
    if ! sshd -t 2> /tmp/ssh_errors; then
        log "Error in sshd config:"
        cat /tmp/ssh_errors | tee -a "$LOG_FILE"
    else
        log "sshd configuration OK."
    fi
    rm -f /tmp/ssh_errors
}

check_ssh_status() {
    log "Checking if sshd is running..."
    if systemctl is-active --quiet sshd || systemctl is-active --quiet ssh; then
        log "sshd service is running."
    else
        log "ERROR: sshd service is not running!"
    fi
}

check_users_and_keys() {
    log "Checking SSH users and keys..."
    for user in "${REQUIRED_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            log "User $user exists."
            KEY_PATH="/home/$user/.ssh/authorized_keys"
            if [[ -f "$KEY_PATH" ]]; then
                log "SSH key exists for $user."
            else
                log "ERROR: SSH key missing for $user!"
            fi
        else
            log "ERROR: User $user does not exist!"
        fi
    done
}

check_ufw_status() {
    if command -v ufw &>/dev/null; then
        log "Checking UFW status..."
        if ufw status | grep -qw "OpenSSH"; then
            log "UFW is allowing SSH."
        else
            log "ERROR: UFW is not allowing SSH."
        fi
    else
        log "UFW not installed."
    fi
}

report_active_sessions() {
    log "Reporting active SSH sessions:"
    who | grep -i "ssh" || log "No active SSH sessions found."
}

handle_input() {
    echo -n "Do you want to restart sshd service if issues are found? (y/n): "
    read restart_choice
    if [[ "$restart_choice" == "y" ]]; then
        log "Attempting to restart sshd..."
        if systemctl restart sshd || systemctl restart ssh; then
            log "sshd restarted successfully."
        else
            log "Failed to restart sshd."
        fi
    fi
}

main() {
    log "========== Starting SSH Maintenance =========="

    check_ssh_config
    check_ssh_status
    check_users_and_keys
    check_ufw_status
    report_active_sessions
    handle_input

    log "========== SSH Maintenance Complete =========="
}

main
