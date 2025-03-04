#!/bin/bash

# Exit on error, but allow us to handle errors gracefully
set -e

BIN_NAME="dripping"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/dripping.service"
CONFIG_DIR="/etc/dripping"
CONFIG_FILE="$CONFIG_DIR/config.json"
STATE_FILE="$CONFIG_DIR/state.json"

# Check if we're running as root or with sudo
if [ "$(id -u)" -ne 0 ] && ! sudo -v &>/dev/null; then
    echo "Error: This script requires root privileges. Please run with sudo."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if systemd is available
if ! command_exists systemctl; then
    echo "Error: This script requires systemd, which is not available on this system."
    exit 1
fi

# Check if dripping is already installed
if [ -f "$INSTALL_DIR/$BIN_NAME" ]; then
    echo "Dripping is already installed. Updating to the latest version..."
else
    echo "Installing Dripping IP Checker..."
fi

# Create configuration directory if it doesn't exist
sudo mkdir -p $CONFIG_DIR

# Download the binary
echo "Downloading binary..."
if ! curl -L -o $BIN_NAME https://github.com/jplaskota/dripping/releases/latest/download/dripping_linux_amd64; then
    echo "Error: Failed to download the binary. Please check your internet connection and try again."
    exit 1
fi

# Verify the binary is executable
chmod +x $BIN_NAME
if ! file $BIN_NAME | grep -q "executable"; then
    echo "Error: The downloaded file is not a valid executable."
    rm $BIN_NAME
    exit 1
fi

# Move the binary to the installation directory
sudo mv $BIN_NAME $INSTALL_DIR

# Create default configuration file if it does not exist.
if [ ! -f "$CONFIG_FILE" ]; then
cat <<EOF | sudo tee $CONFIG_FILE
{
    "expected_ip": "1.2.3.4",
    "discord_webhook_url": "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token"
}
EOF
fi

# Install the systemd service file.
echo "Installing systemd service..."
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Dripping IP Checker Service
After=network.target

[Service]
ExecStart=$INSTALL_DIR/dripping -config $CONFIG_FILE -state /etc/dripping/state.json
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Create an empty state file if it does not exist
if [ ! -f "$STATE_FILE" ]; then
    echo "{}" | sudo tee $STATE_FILE > /dev/null
    sudo chmod 644 $STATE_FILE
fi

# Reload systemd and manage the service
echo "Configuring and starting the service..."
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable dripping.service

# Restart the service if it's already running, otherwise start it
if sudo systemctl is-active --quiet dripping.service; then
    sudo systemctl restart dripping.service
    echo "Dripping service has been updated and restarted."
else
    sudo systemctl start dripping.service
    echo "Dripping service has been started."
fi

echo "Installation complete. Dripping is now monitoring your IP address."
echo "You can check the service status with: sudo systemctl status dripping.service"
echo "Configuration file is located at: $CONFIG_FILE"
echo "State file is located at: $STATE_FILE"
