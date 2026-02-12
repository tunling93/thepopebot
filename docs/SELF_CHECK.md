# thepopebot Self-Check System

Autonomous health monitoring and auto-fix for the Event Handler layer.

## Overview

The self-check system performs comprehensive validation of:
1. **Telegram Webhook** - Sync with ngrok tunnel URL
2. **Model Support** - Verify web_search_20250305 compatibility
3. **Process Management** - Event handler lifecycle
4. **Endpoint Testing** - Validate webhook responses

## Quick Start

```bash
cd event_handler
./self-check.sh
```

**Prerequisites:**
- `.env` file configured with required credentials
- ngrok running (for webhook verification)
- `jq` installed for JSON parsing

## What It Does

### 1. Telegram Webhook Verification
- Fetches current webhook URL from Telegram API
- Gets ngrok tunnel URL from local API (http://127.0.0.1:4040)
- Compares and updates if mismatched
- Verifies no `last_error_message` in webhook status

### 2. Model Support Validation
- Checks current `DEFAULT_MODEL` in `event_handler/claude/index.js`
- Verifies compatibility with `web_search_20250305` tool
- Queries Anthropic API to confirm model availability

**web_search Compatible Models:**
- ✓ `claude-opus-4-20250514`
- ✓ `claude-sonnet-4-5-20250929`
- ✓ `claude-sonnet-4-20250514`
- ✓ `claude-haiku-4-5-20251001` (cheapest)
- ✗ `claude-haiku-4-20250514` (older Haiku - not supported)
- ✗ `claude-3-haiku-20240307` (Claude 3 series)

### 3. Process Management
- Checks if event handler is already running
- Gracefully stops existing process if found
- Starts event handler using pm2 (preferred) or nohup
- Verifies process listens on port 3000 within 5 seconds

### 4. Endpoint Testing
- POSTs test payload to `/telegram/webhook`
- Verifies 200 OK response
- Re-checks webhook status for errors

## Output

The script produces:
1. **Console output** with colored status indicators
2. **Log file** at `/tmp/thepopebot-self-check-YYYYMMDD-HHMMSS.log`
3. **Summary report** with before/after comparison

### Example Output

```
=========================================
1. TELEGRAM WEBHOOK VERIFICATION
=========================================

Fetching current webhook status...
Current webhook URL: https://old-url.ngrok.io/telegram/webhook
⚠ Webhook error: Connection timeout

Fetching ngrok tunnel URL...
Expected webhook URL: https://new-url.ngrok.io/telegram/webhook
⚠ Webhook URL mismatch - updating...
✓ Webhook updated successfully
✓ Webhook is healthy (no errors)

=========================================
2. MODEL SUPPORT VALIDATION
=========================================

Current DEFAULT_MODEL: claude-haiku-4-5-20251001
✓ Current model supports web_search_20250305

Verifying model availability with Anthropic API...
✓ Model claude-haiku-4-5-20251001 is available

=========================================
3. EVENT HANDLER PROCESS MANAGEMENT
=========================================

Checking for existing event handler process...
No existing process found

Checking port 3000...
Port 3000 status before: Port 3000 not in use

Starting event handler...
Using pm2 to start process...
✓ Event handler started with pm2

Verifying process is listening on port 3000...
Port 3000 status after: LISTEN 0 511 *:3000 *:* users:(("node",pid=12345))
✓ Event handler is listening on port 3000

=========================================
4. ENDPOINT TESTING
=========================================

Testing /telegram/webhook endpoint...
✓ Endpoint returned 200 OK

Final webhook verification...
✓ Final webhook status: HEALTHY

=========================================
SUMMARY
=========================================

Webhook URL:
  Before: https://old-url.ngrok.io/telegram/webhook
  After:  https://new-url.ngrok.io/telegram/webhook

Model:
  Current: claude-haiku-4-5-20251001
  Compatible with web_search: YES

Port 3000:
  Before: NOT IN USE
  After:  LISTENING

Final Status: PASS

Report saved to: /tmp/thepopebot-self-check-20260212-080630.log

✓ Self-check complete!
```

## Integration with Cron

Add to `operating_system/CRONS.json` for scheduled health checks:

```json
{
  "name": "self-check",
  "schedule": "0 */6 * * *",
  "type": "command",
  "command": "bash event_handler/self-check.sh",
  "enabled": true
}
```

This runs the self-check every 6 hours and auto-fixes any issues.

## Troubleshooting

### Error: "ngrok API not accessible"
**Solution:** Start ngrok with `ngrok http 3000`

### Error: ".env file not found"
**Solution:** Create `event_handler/.env` from `.env.example`

### Error: "TELEGRAM_BOT_TOKEN not set"
**Solution:** Add required credentials to `.env`

### Warning: "Model does NOT support web_search_20250305"
**Solution:** Update model in code:
```bash
# Edit event_handler/claude/index.js
const DEFAULT_MODEL = 'claude-haiku-4-5-20251001';
```

### Error: "Event handler not listening on port 3000"
**Solution:** Check logs:
```bash
# If using pm2
pm2 logs thepopebot-handler

# If using nohup
tail -f /tmp/event-handler.log
```

## Manual Webhook Update

If you need to manually update the webhook:

```bash
# Get current status
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo" | jq

# Set new webhook
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://your-ngrok-url.ngrok.io/telegram/webhook"}'

# Delete webhook
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/deleteWebhook"
```

## Related Documentation

- [Configuration Guide](CONFIGURATION.md)
- [Event Handler Architecture](../CLAUDE.md#event-handler-layer)
- [Cost Optimization](COST_OPTIMIZATION.md)
