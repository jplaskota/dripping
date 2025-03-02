# Dripping

Dripping is a lightweight IP monitor written in Go that tracks your public IP address and sends Discord notifications when it changes. It compares the current IP (fetched from ifconfig.co) with the expected IP specified in a JSON configuration file and persists its state in a JSON file to avoid duplicate alerts after restarts. Licensed under GNU GPL 3.0.

## Features

- Fetches current IP from [ifconfig.co](https://ifconfig.co)
- Compares fetched IP with the expected IP from `config.json`
- Sends Discord notifications when the IP changes or returns to the expected state
- Checks your IP every 5 minutes
- Persists state in a JSON file for consistency across restarts

## Installation

Install Dripping with a single command:

```bash
curl -sSL https://github.com/yourusername/dripping/raw/main/dripping_install.sh | bash
```
