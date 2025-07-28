#!/usr/bin/env bash
# mesh.sh

# This script is intended to be executed from within the cloned git archive
# of harden_meshtasticd and will error if executed outside of that dir

# Set up for meshtasticd deb install
echo 'deb http://download.opensuse.org/repositories/network:/Meshtastic:/beta/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/network:Meshtastic:beta.list

curl -fsSL https://download.opensuse.org/repositories/network:Meshtastic:beta/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg > /dev/null

apt-get update

# Get m*d and pip which we will need later for the CLI
apt-get install -y meshtasticd pip

# Get nebramesh hat config files
wget -O /etc/meshtasticd/available.d/NebraHat_1W.yaml https://github.com/wehooper4/Meshtastic-Hardware/raw/refs/heads/main/NebraHat/NebraHat_1W.yaml
wget -O /etc/meshtasticd/available.d/NebraHat_2W.yaml https://github.com/wehooper4/Meshtastic-Hardware/raw/refs/heads/main/NebraHat/NebraHat_2W.yaml

# Install CLI interface (requires python)
# Note we are not using virtual env, use a different approach if this is important to you
pip install --break-system-packages meshtastic

# copy util shims
cp utils/* /usr/local/bin

echo "Copy the appropriate config file from /etc/meshtasticd/available.d to the config.d file"
