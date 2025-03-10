# Dripping

Dripping is a lightweight IP monitor written in Go that tracks your public IP address and sends Discord notifications when it changes. It compares the current IP (fetched from ifconfig.co) with the expected IP specified in a JSON configuration file.

## Features

- Fetches current IP from [ifconfig.co](https://ifconfig.co)
- Compares fetched IP with the expected IP from `config.json`
- Sends Discord notifications when the IP changes or returns to the expected state
- Checks your IP every 5 minutes
- Persists state in a JSON file for consistency across restarts

## Configuration

Configure Dripping with a JSON file (`config.json`):

| Parameter | Type | Description | Example |
|-----------|------|-------------|--------|
| `expected_ip` | String | Your expected network IP address | `"203.0.113.1"` |
| `discord_webhook_url` | String | Discord webhook URL for notifications | `"https://discord.com/api/webhooks/your_webhook_id/your_webhook_token"` |
| `check_interval` | Integer | IP check frequency (minutes) | `5` |
| `change_message` | String | Alert when IP changes (use `%s` for IP and timestamp) | `"Warning: IP changed! Current IP: %s at %s"` |
| `restore_message` | String | Alert when IP returns to expected (use `%s` for IP and timestamp) | `"Info: IP returned to expected state (%s) at %s"` |

Example configuration:

```json
{
  "expected_ip": "203.0.113.1",
  "discord_webhook_url": "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token",
  "check_interval": 5,
  "change_message": "Warning: IP changed! Current IP: %s at %s",
  "restore_message": "Info: IP returned to expected state (%s) at %s"
}
```

## Installation

Install Dripping with a single command:

```bash
curl -sSL https://github.com/jplaskota/dripping/raw/main/dripping_install.sh | bash
```
