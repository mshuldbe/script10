#!/bin/bash

if grep -q "Ubuntu" /etc/os-release; then
    echo "Detected Ubuntu"
    # Run Ubuntu-specific commands
    sudo apt update && sudo apt install -y ufw
    sudo systemctl enable ufw
    sudo systemctl start ufw

elif grep -q "CentOS" /etc/os-release; then
    echo "Detected CentOS"
    # Run CentOS-specific commands
    sudo yum install -y epel-release
    sudo yum install -y ufw
    sudo systemctl enable ufw
    sudo systemctl start ufw

else
    echo "Unsupported OS"
    exit 1
fi