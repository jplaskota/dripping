package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

// Config stores the application settings.
type Config struct {
	ExpectedIP        string `json:"expected_ip"`
	DiscordWebhookURL string `json:"discord_webhook_url"`
}

// State stores the last fetched IP and the event time.
type State struct {
	Matches   bool   `json:"matches"`   // true if the current IP matches the expected one
	IP        string `json:"ip"`        // fetched IP address
	Timestamp string `json:"timestamp"` // event time (HH:MM:SS)
}

// loadConfig reads the configuration from a JSON file.
func loadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}
	return &config, nil
}

// loadState reads the last state from a JSON file.
func loadState(path string) (*State, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var state State
	if err := json.Unmarshal(data, &state); err != nil {
		return nil, err
	}
	return &state, nil
}

// saveState writes the state to a JSON file.
func saveState(path string, state *State) error {
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}

// getCurrentIP fetches the current IP address from ifconfig.co.
func getCurrentIP() (string, error) {
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	resp, err := client.Get("https://ifconfig.co")
	if err != nil {
		return "", fmt.Errorf("failed to fetch IP: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %v", err)
	}
	return strings.TrimSpace(string(body)), nil
}

// sendDiscordNotification sends a notification to Discord via webhook.
func sendDiscordNotification(webhookURL, message string) error {
	payload := map[string]string{"content": message}
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}

	client := &http.Client{
		Timeout: 10 * time.Second,
	}
	resp, err := client.Post(webhookURL, "application/json", bytes.NewReader(payloadBytes))
	if err != nil {
		return fmt.Errorf("failed to send notification: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("failed to send notification, status code: %d", resp.StatusCode)
	}
	return nil
}

func main() {
	// Parse command line flags for configuration file and state file paths.
	configPath := flag.String("config", "config.json", "Path to configuration file")
	statePath := flag.String("state", "state.json", "Path to persistent state file")
	flag.Parse()

	// Load configuration.
	config, err := loadConfig(*configPath)
	if err != nil {
		log.Fatalf("Error loading config: %v", err)
	}

	// Attempt to load the previous state. If the file doesn't exist, lastState will be nil.
	lastState, err := loadState(*statePath)
	if err != nil {
		if os.IsNotExist(err) {
			log.Println("State file not found, starting with a fresh state.")
			lastState = nil
		} else {
			log.Printf("Error loading state: %v", err)
		}
	}

	log.Println("Starting Dripping IP checker...")

	for {
		currentIP, err := getCurrentIP()
		if err != nil {
			log.Printf("Error fetching current IP: %v", err)
		} else {
			now := time.Now().Format("15:04:05")
			matches := (currentIP == config.ExpectedIP)
			log.Printf("Current IP: %s | Expected IP: %s", currentIP, config.ExpectedIP)

			var lastMatches bool
			// If a previous state exists, use its value; otherwise, treat the current state as the reference.
			if lastState != nil {
				lastMatches = lastState.Matches
			} else {
				lastMatches = matches
			}

			// Check if the state has changed.
			if matches != lastMatches {
				var message string
				if !matches {
					message = fmt.Sprintf("Warning: IP changed! Current IP: %s at %s", currentIP, now)
				} else {
					message = fmt.Sprintf("Info: IP returned to expected state (%s) at %s", config.ExpectedIP, now)
				}
				if err := sendDiscordNotification(config.DiscordWebhookURL, message); err != nil {
					log.Printf("Error sending Discord notification: %v", err)
				} else {
					log.Println("Notification sent.")
				}
				// Update and save the new state.
				newState := &State{
					Matches:   matches,
					IP:        currentIP,
					Timestamp: now,
				}
				if err := saveState(*statePath, newState); err != nil {
					log.Printf("Error saving state: %v", err)
				}
				lastState = newState
			} else {
				log.Println("No state change detected. No notification sent.")
			}
		}
		// Wait 5 minutes before checking again.
		time.Sleep(5 * time.Minute)
	}
}
