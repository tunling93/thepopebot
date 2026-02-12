Autonomous End-to-End Self-Check: Telegram Webhook + web_search Model Support + Event Handler Process Management

Repository: tunling93/thepopebot

This job performs a complete self-check and auto-fix without user interaction:

## Task Breakdown

### 1. Telegram Webhook Verification & Sync
- Call Telegram Bot API getWebhookInfo to retrieve current webhook URL
- Call ngrok local API (http://127.0.0.1:4040/api/tunnels) to get public tunnel URL
- Compare webhook URL with ngrok tunnel + /telegram/webhook path
- If mismatch: update Telegram webhook to correct URL via Bot API
- Verify no last_error_message in webhook status
- Record webhook URL before and after

### 2. Model Support Validation for web_search_20250305
- Read current EVENT_HANDLER_MODEL from environment variables and config files
- Call Anthropic /v1/models API to list available models
- Check if current model is in the known web_search-compatible list:
  * claude-opus-4-20250514 ✓
  * claude-sonnet-4-5-20250929 ✓
  * claude-sonnet-4-20250514 ✓
  * claude-haiku-4-5-20251001 ✓
  * claude-3-haiku-20240307 ✗ (does NOT support web_search_20250305)
- If current model does not support web_search_20250305: switch to claude-haiku-4-5-20251001 (cheapest compatible model)
- Update .github/workflows or environment configuration with new model
- Record model before and after

### 3. Event Handler Process Management
- Check if event_handler is running (ps aux check for node server.js)
- Verify it listens on port 3000 (using netstat/ss/lsof)
- If process is running: gracefully kill it
- Start event_handler using: nohup node event_handler/server.js > /tmp/event-handler.log 2>&1 &
- Alternatively, if pm2 is available on system, use: pm2 start event_handler/server.js --name thepopebot-handler
- Verify process is listening on port 3000 within 5 seconds
- Record port 3000 status before and after
- Keep process running in background

### 4. Test /telegram/webhook Endpoint
- POST test payload to {NGROK_PUBLIC_URL}/telegram/webhook
- Verify 200 OK response
- Verify Telegram webhook has no last_error_message

### 5. Commit & Report
- Commit all changes with message: "thepopebot: self-check auto-fix - webhook sync, model validation, process restart"
- Create detailed report including:
  * Final STATUS: PASS or FAIL
  * Webhook URL before → after
  * Model before → after
  * Port 3000 status (running/not running before and after)
  * Exact commands executed
  * Diff of all changed files

Output this report to stdout at end of job.