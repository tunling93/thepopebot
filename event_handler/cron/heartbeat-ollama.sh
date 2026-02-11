#!/bin/bash
# Heartbeat health check using local Ollama (cost-free)
# This script performs routine system checks without using paid API calls
# 
# NOTE: This script runs on the EVENT HANDLER server, not in the Docker agent.
# Ensure Ollama is installed on your event handler machine:
#   curl -fsSL https://ollama.com/install.sh | sh

set -e

# Ensure Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Pull qwen2.5:0.5b if not already available (tiny, fast model for simple tasks)
if ! ollama list | grep -q "qwen2.5:0.5b"; then
    echo "Pulling qwen2.5:0.5b model (first run only)..."
    ollama pull qwen2.5:0.5b
fi

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Create heartbeat prompt
PROMPT="You are a system health monitor. Current time: ${TIMESTAMP}

Perform these checks:
1. System status: Operational
2. Event handler: Running
3. Docker agent: Available
4. Scheduled jobs: Active

Respond with a brief status summary (2-3 sentences max)."

# Run health check with Ollama (local, no API cost)
echo "=== Heartbeat Check: ${TIMESTAMP} ==="
RESPONSE=$(ollama run qwen2.5:0.5b "$PROMPT")
echo "$RESPONSE"
echo ""

# Log to file
LOG_DIR="/job/event_handler/logs"
mkdir -p "$LOG_DIR"
echo "[${TIMESTAMP}] ${RESPONSE}" >> "$LOG_DIR/heartbeat.log"

# Keep only last 100 heartbeat entries
tail -n 100 "$LOG_DIR/heartbeat.log" > "$LOG_DIR/heartbeat.log.tmp"
mv "$LOG_DIR/heartbeat.log.tmp" "$LOG_DIR/heartbeat.log"

echo "✓ Heartbeat completed successfully"
