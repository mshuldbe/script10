#!/bin/bash

# SSH Maintenance Script for Ubuntu and CentOS

REQUIRED_USERS=("user1" "user2")
LOG_FILE="/var/log/ssh_maintenance.log"

log() {
    echo "$(date '+%F %T') - $1" | tee -a "$LOG_FILE"
}

check_ssh_config() {
    log "Checking sshd configuration..."
    if ! sshd -t 2> /tmp/ssh_errors; then
        log "ERROR in sshd config:"
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
        else
            echo -n "User $user does not exist. Create now? (y/n): "
            read create_user
            if [[ "$create_user" == "y" ]]; then
                useradd -m -s /bin/bash "$user" && log "User $user created."
            else
                log "Skipped creating user $user."
                continue
            fi
        fi

        USER_HOME=$(eval echo "~$user")
        SSH_DIR="$USER_HOME/.ssh"
        KEY_PATH="$SSH_DIR/authorized_keys"

        if [[ -f "$KEY_PATH" ]]; then
            log "SSH key exists for $user."
        else
            echo -n "SSH key for $user is missing. Generate one now? (y/n): "
            read create_key
            if [[ "$create_key" == "y" ]]; then
                mkdir -p "$SSH_DIR"
                chmod 700 "$SSH_DIR"
                chown "$user:$user" "$SSH_DIR"

                su - "$user" -c "ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''"
                cat "$USER_HOME/.ssh/id_rsa.pub" > "$KEY_PATH"
                chmod 600 "$KEY_PATH"
                chown "$user:$user" "$KEY_PATH"
                log "New SSH key pair generated for $user."
            else
                log "Skipped generating key for $user."
            fi
        fi
    done
}

check_ufw_status() {
    if command -v ufw &>/dev/null; then
        log "Checking UFW status..."
        UFW_STATUS=$(ufw status | head -n1)
        if [[ "$UFW_STATUS" == "Status: inactive" ]]; then
            log "UFW is inactive. Enabling it..."
            ufw allow OpenSSH && log "Allowed OpenSSH through UFW."
            echo "y" | ufw enable && log "UFW has been enabled."
        else
            if ufw status | grep -qw "OpenSSH"; then
                log "UFW is active and allowing SSH."
            else
                log "UFW is active but not allowing SSH. Fixing..."
                ufw allow OpenSSH && log "OpenSSH allowed through UFW."
            fi
        fi
    else
        log "UFW not installed. Skipping UFW checks."
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
