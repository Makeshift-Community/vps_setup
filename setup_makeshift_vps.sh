#!/usr/bin/bash

# Exit on error
set -e

# Check if user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 2
fi

# Disclaimer
echo This script will set up the Nova bots for the Makeshift Discord.
echo ""

# Variables
SHELL_PATH=/usr/bin/bash

# Additional checks
echo Current shell: $SHELL_PATH
echo "Proceed? (y/n)"
read -r proceed
if [ "$proceed" != "y" ]
then
  exit
fi

# Update and upgrade
echo Updating and upgrading...
apt update
apt upgrade --assume-yes

# Install dependencies
echo Installing dependencies...
apt install --assume-yes htop

# Enable and configure SWAP
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" | tee -a /etc/fstab
echo "vm.swappiness=10" | tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | tee -a /etc/sysctl.conf

# Create users
echo Creating users...
useradd --create-home --shell $SHELL_PATH nova-logs
useradd --create-home --shell $SHELL_PATH nova-makeshift
useradd --create-home --shell $SHELL_PATH octavia

# Run user scripts

# Add systemd services
echo Adding systemd services...
cp nova-logs.service /etc/systemd/system/
cp nova-makeshift.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable nova-logs
systemctl start nova-logs
systemctl enable nova-makeshift
systemctl start nova-makeshift

journalctl -u nova-logs.service
journalctl -u nova-makeshift.service

# Clean history
echo Cleaning history...
history -c

# Reboot
echo Installation complete. Rebooting in 10 seconds...
(sleep 10 && reboot) &
echo "Don't forget to  >> logout <<  ;)"
