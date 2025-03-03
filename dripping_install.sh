#!/bin/bash
set -e

BIN_NAME="dripping"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/dripping.service"
CONFIG_DIR="/etc/dripping"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo "Installing Dripping IP Checker..."

# Create configuration directory if it doesn't exist.
sudo mkdir -p $CONFIG_DIR

# Download the binary (replace the URL with the actual download URL for your binary).
echo "Downloading binary..."
curl -L -o $BIN_NAME https://github.com/jplaskota/dripping/releases/latest/download/dripping_linux_amd64
chmod +x $BIN_NAME
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

# Create an empty state file if it does not exist.
STATE_FILE="/etc/dripping/state.json"
if [ ! -f "$STATE_FILE" ]; then
  sudo echo "{}" > $STATE_FILE
fi

# Reload systemd and start the service.
sudo systemctl daemon-reload
sudo systemctl enable dripping.service
sudo systemctl start dripping.service

echo "Installation complete."
