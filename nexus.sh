#!/bin/bash

set -e

# Define variables
NEXUS_VERSION="3.78.2-04"
NEXUS_FILENAME="nexus-unix-x86-64-${NEXUS_VERSION}.tar.gz"
NEXUS_DOWNLOAD_URL="https://download.sonatype.com/nexus/3/${NEXUS_FILENAME}"
INSTALL_DIR="/opt"
NEXUS_DIR="${INSTALL_DIR}/nexus"
NEXUS_DATA_DIR="${INSTALL_DIR}/sonatype-work"

# Update and install required packages
echo "Updating system..."
sudo yum update -y
echo "Installing required packages..."
sudo yum install -y wget java-17-amazon-corretto

# Create nexus user
echo "Creating nexus user..."
sudo useradd --system --no-create-home nexus || true

# Create directories
echo "Creating directories..."
cd $INSTALL_DIR
sudo wget $NEXUS_DOWNLOAD_URL
sudo tar -xvzf $NEXUS_FILENAME
sudo mv nexus-${NEXUS_VERSION} nexus
sudo mkdir -p $NEXUS_DATA_DIR

# Set ownership
sudo chown -R nexus:nexus $NEXUS_DIR
sudo chown -R nexus:nexus $NEXUS_DATA_DIR

# Configure run_as_user
echo 'run_as_user="nexus"' | sudo tee ${NEXUS_DIR}/bin/nexus.rc

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOL
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=${NEXUS_DIR}/bin/nexus start
ExecStop=${NEXUS_DIR}/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

# Enable and start service
echo "Enabling and starting Nexus..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# Print status
echo "Nexus installation complete!"
sudo systemctl status nexus

