#!/usr/bin/bash

# Exit on error
set -o errexit

# Check if user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 2
fi

# Disclaimer
echo This script will set up the Nova bots for the Makeshift Discord.
echo ""

# Variables
NODE_MAJOR=20
SHELL_PATH=/usr/bin/bash

# Additional checks
echo Configured Node LTS version: $NODE_MAJOR
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
apt install --assume-yes git

# Install Node
echo Installing Node...
apt install --assume-yes ca-certificates curl gnupg
mkdir --parents /etc/apt/keyrings
curl --fail --silent --show-error --location https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --output /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt update
apt install --assume-yes nodejs
npm install --global npm@latest

# Install PM2
echo Installing PM2...
npm install pm2 --global

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

# Setup nova-logs
pushd /home/nova-logs/
echo Cloning nova-logs git repository...
su nova-logs --command="git clone --branch stable --depth 1 https://github.com/Makeshift-Community/nova-logs.git"
pushd nova-logs/
echo Installing nova-logs dependencies...
su nova-logs --command="npm install"
echo Enter token for nova-logs:
read -r token
su nova-logs --command="echo \"export default \\\"$token\\\";\" > token.js"
echo Starting nova-logs in PM2...
su nova-logs --command="pm2 start ecosystem.config.cjs --env production"
echo Creating PM2 startup script...
su nova-logs --command="pm2 startup; exit 0"
echo Registering nova-logs as a service...
env PATH="$PATH":/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd --user nova-logs --hp /home/nova-logs
echo Saving PM2 process list...
su nova-logs --command="pm2 save"
popd
popd

# Setup nova-makeshift
pushd /home/nova-makeshift/
echo Cloning nova-makeshift git repository...
su nova-makeshift --command="git clone --branch stable --depth 1 https://github.com/Makeshift-Community/nova-makeshift.git"
pushd nova-makeshift/
echo Installing nova-makeshift dependencies...
su nova-makeshift --command="npm install"
echo Enter token for nova-makeshift:
read -r token
su nova-makeshift --command="echo \"export default \\\"$token\\\";\" > token.js"
echo Starting nova-makeshift in PM2...
su nova-makeshift --command="pm2 start ecosystem.config.cjs --env production"
echo Creating PM2 startup script...
su nova-makeshift --command="pm2 startup; exit 0"
echo Registering nova-makeshift as a service...
env PATH="$PATH":/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd --user nova-makeshift --hp /home/nova-makeshift
echo Saving PM2 process list...
su nova-makeshift --command="pm2 save"
popd
popd


# Setup octavia


# Clean history
echo Cleaning history...
history -c

# Reboot
echo Installation complete. Rebooting in 10 seconds...
(sleep 10 && reboot) &
echo "Don't forget to  >> logout <<  ;)"
