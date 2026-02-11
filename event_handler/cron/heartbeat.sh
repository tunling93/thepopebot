#!/bin/bash
# Heartbeat health check using local Ollama (free, no API costs)
# This runs every 30 minutes to verify the agent is healthy

set -e

echo "=== thepopebot Heartbeat Check ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Check if Ollama is available (Docker agent only)
if ! command -v ollama &> /dev/null; then
    echo "⚠️  Ollama not installed - skipping LLM health check"
    echo "Status: OK (Event Handler healthy, no Ollama)"
    exit 0
fi

# Start Ollama service if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Pull a lightweight model if not already present (qwen2.5:0.5b is ~400MB, very fast)
MODEL="qwen2.5:0.5b"
if ! ollama list | grep -q "$MODEL"; then
    echo "Pulling lightweight model $MODEL..."
    ollama pull "$MODEL"
fi

# Simple health check prompt
PROMPT="You are a system health monitor. Respond with exactly 'HEALTHY' if you can process this message, nothing else."

# Run health check with timeout
RESPONSE=$(timeout 10s ollama run "$MODEL" "$PROMPT" 2>&1 || echo "TIMEOUT")

if echo "$RESPONSE" | grep -qi "HEALTHY"; then
    echo "✅ Status: HEALTHY"
    echo "LLM Response: $RESPONSE"
    exit 0
else
    echo "❌ Status: UNHEALTHY"
    echo "LLM Response: $RESPONSE"
    exit 1
fi
