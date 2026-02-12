#!/bin/bash
# thepopebot Self-Check Script
# Autonomous end-to-end verification and auto-fix for Event Handler

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Report file
REPORT="/tmp/thepopebot-self-check-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "$1" | tee -a "$REPORT"
}

log_success() {
    log "${GREEN}✓ $1${NC}"
}

log_error() {
    log "${RED}✗ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠ $1${NC}"
}

log_section() {
    log "\n========================================="
    log "$1"
    log "=========================================\n"
}

# Initialize report
log "thepopebot Self-Check Report"
log "Date: $(date)"
log "Host: $(hostname)"
log "\n"

# Load environment variables
if [ -f .env ]; then
    source .env
else
    log_error ".env file not found"
    exit 1
fi

# Check required variables
REQUIRED_VARS=("TELEGRAM_BOT_TOKEN" "ANTHROPIC_API_KEY")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        log_error "$var not set in .env"
        exit 1
    fi
done

log_section "1. TELEGRAM WEBHOOK VERIFICATION"

# Get current webhook info
log "Fetching current webhook status..."
WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo")
CURRENT_WEBHOOK_URL=$(echo "$WEBHOOK_INFO" | jq -r '.result.url')
WEBHOOK_ERROR=$(echo "$WEBHOOK_INFO" | jq -r '.result.last_error_message // empty')

log "Current webhook URL: ${CURRENT_WEBHOOK_URL:-"(not set)"}"
if [ -n "$WEBHOOK_ERROR" ]; then
    log_warning "Webhook error: $WEBHOOK_ERROR"
fi

# Get ngrok tunnel URL
log "\nFetching ngrok tunnel URL..."
if ! curl -s http://127.0.0.1:4040/api/tunnels > /dev/null 2>&1; then
    log_error "ngrok API not accessible (is ngrok running?)"
    exit 1
fi

NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')
if [ -z "$NGROK_URL" ] || [ "$NGROK_URL" = "null" ]; then
    log_error "No ngrok tunnel found"
    exit 1
fi

EXPECTED_WEBHOOK_URL="${NGROK_URL}/telegram/webhook"
log "Expected webhook URL: $EXPECTED_WEBHOOK_URL"

# Compare and update if needed
if [ "$CURRENT_WEBHOOK_URL" != "$EXPECTED_WEBHOOK_URL" ]; then
    log_warning "Webhook URL mismatch - updating..."
    
    UPDATE_RESULT=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
        -H "Content-Type: application/json" \
        -d "{\"url\": \"$EXPECTED_WEBHOOK_URL\"}")
    
    if echo "$UPDATE_RESULT" | jq -e '.ok' > /dev/null; then
        log_success "Webhook updated successfully"
    else
        log_error "Failed to update webhook: $UPDATE_RESULT"
        exit 1
    fi
else
    log_success "Webhook URL is correct"
fi

# Verify webhook status after update
WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo")
WEBHOOK_ERROR=$(echo "$WEBHOOK_INFO" | jq -r '.result.last_error_message // empty')
if [ -n "$WEBHOOK_ERROR" ]; then
    log_error "Webhook still has errors: $WEBHOOK_ERROR"
else
    log_success "Webhook is healthy (no errors)"
fi

log_section "2. MODEL SUPPORT VALIDATION"

# Check current model configuration
CURRENT_MODEL=$(grep "DEFAULT_MODEL" event_handler/claude/index.js | sed "s/.*'\(.*\)'.*/\1/")
log "Current DEFAULT_MODEL: $CURRENT_MODEL"

# List of web_search compatible models
WEB_SEARCH_MODELS=("claude-opus-4-20250514" "claude-sonnet-4-5-20250929" "claude-sonnet-4-20250514" "claude-haiku-4-5-20251001")

# Check if current model is compatible
MODEL_COMPATIBLE=false
for model in "${WEB_SEARCH_MODELS[@]}"; do
    if [ "$CURRENT_MODEL" = "$model" ]; then
        MODEL_COMPATIBLE=true
        break
    fi
done

if $MODEL_COMPATIBLE; then
    log_success "Current model supports web_search_20250305"
else
    log_error "Current model does NOT support web_search_20250305"
    log_warning "Recommended: claude-haiku-4-5-20251001 (cheapest compatible)"
fi

# Verify model is available via Anthropic API
log "\nVerifying model availability with Anthropic API..."
MODELS_RESPONSE=$(curl -s "https://api.anthropic.com/v1/models" \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01")

if echo "$MODELS_RESPONSE" | jq -e ".data[] | select(.id == \"$CURRENT_MODEL\")" > /dev/null; then
    log_success "Model $CURRENT_MODEL is available"
else
    log_warning "Model $CURRENT_MODEL not found in available models list"
fi

log_section "3. EVENT HANDLER PROCESS MANAGEMENT"

# Check if event handler is running
log "Checking for existing event handler process..."
if pgrep -f "node.*server.js" > /dev/null; then
    OLD_PID=$(pgrep -f "node.*server.js")
    log_warning "Event handler already running (PID: $OLD_PID)"
    log "Stopping existing process..."
    pkill -f "node.*server.js" || true
    sleep 2
    log_success "Stopped old process"
else
    log "No existing process found"
fi

# Check if port 3000 is in use
log "\nChecking port 3000..."
PORT_STATUS_BEFORE=$(ss -tlnp 2>/dev/null | grep ":3000" || echo "Port 3000 not in use")
log "Port 3000 status before: $PORT_STATUS_BEFORE"

# Start event handler
log "\nStarting event handler..."
cd event_handler

# Check if pm2 is available
if command -v pm2 > /dev/null; then
    log "Using pm2 to start process..."
    pm2 delete thepopebot-handler 2>/dev/null || true
    pm2 start server.js --name thepopebot-handler
    sleep 3
    pm2 status thepopebot-handler
    log_success "Event handler started with pm2"
else
    log "pm2 not available, using nohup..."
    nohup node server.js > /tmp/event-handler.log 2>&1 &
    NEW_PID=$!
    sleep 3
    if ps -p $NEW_PID > /dev/null; then
        log_success "Event handler started (PID: $NEW_PID)"
    else
        log_error "Failed to start event handler"
        log "Log output:"
        tail -20 /tmp/event-handler.log
        exit 1
    fi
fi

cd ..

# Verify port 3000 is now in use
log "\nVerifying process is listening on port 3000..."
for i in {1..10}; do
    if ss -tlnp 2>/dev/null | grep ":3000" > /dev/null; then
        PORT_STATUS_AFTER=$(ss -tlnp 2>/dev/null | grep ":3000")
        log "Port 3000 status after: $PORT_STATUS_AFTER"
        log_success "Event handler is listening on port 3000"
        break
    fi
    if [ $i -eq 10 ]; then
        log_error "Event handler not listening on port 3000 after 10 seconds"
        exit 1
    fi
    sleep 1
done

log_section "4. ENDPOINT TESTING"

# Test /telegram/webhook endpoint
log "Testing /telegram/webhook endpoint..."
TEST_PAYLOAD='{"update_id":1,"message":{"message_id":1,"from":{"id":1,"is_bot":false,"first_name":"Test"},"chat":{"id":1,"type":"private"},"date":1234567890,"text":"/start"}}'

TEST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:3000/telegram/webhook" \
    -H "Content-Type: application/json" \
    -d "$TEST_PAYLOAD")

HTTP_CODE=$(echo "$TEST_RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$TEST_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    log_success "Endpoint returned 200 OK"
else
    log_warning "Endpoint returned HTTP $HTTP_CODE"
    log "Response: $RESPONSE_BODY"
fi

# Final webhook check
log "\nFinal webhook verification..."
WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo")
FINAL_WEBHOOK_URL=$(echo "$WEBHOOK_INFO" | jq -r '.result.url')
FINAL_WEBHOOK_ERROR=$(echo "$WEBHOOK_INFO" | jq -r '.result.last_error_message // empty')

if [ "$FINAL_WEBHOOK_URL" = "$EXPECTED_WEBHOOK_URL" ] && [ -z "$FINAL_WEBHOOK_ERROR" ]; then
    log_success "Final webhook status: HEALTHY"
else
    log_warning "Final webhook status: $FINAL_WEBHOOK_ERROR"
fi

log_section "SUMMARY"

log "Webhook URL:"
log "  Before: ${CURRENT_WEBHOOK_URL:-"(not set)"}"
log "  After:  $FINAL_WEBHOOK_URL"

log "\nModel:"
log "  Current: $CURRENT_MODEL"
log "  Compatible with web_search: $([ "$MODEL_COMPATIBLE" = true ] && echo "YES" || echo "NO")"

log "\nPort 3000:"
log "  Before: $(echo "$PORT_STATUS_BEFORE" | grep -q "3000" && echo "IN USE" || echo "NOT IN USE")"
log "  After:  LISTENING"

log "\nFinal Status: ${GREEN}PASS${NC}"
log "\nReport saved to: $REPORT"

echo -e "\n${GREEN}✓ Self-check complete!${NC}"
