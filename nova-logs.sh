#!/usr/bin/bash

# Exit on error
set -e

# Setup nova-logs
pushd /home/nova-logs/

# Install Node
echo Installing Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24

echo Cloning nova-logs git repository...
git clone --branch stable --depth 1 https://github.com/Makeshift-Community/nova-logs.git

# Install dependecies
pushd nova-logs/
echo Installing nova-logs dependencies...
npm install
echo Enter token for nova-logs:
read -r token
printf "NODE_ENV=\"production\"\nTOKEN=\"%s\"\n" "$token" > .env

# Test
echo Testing...
echo Hint: press Ctrl+C to stop the bot after verifying it started successfully.
npm run start

popd
popd
