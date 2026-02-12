# Quick Start Guide - After Prerequisites Are Met

Once you have credentials configured, run these commands to complete the setup:

## 1. Install Dependencies
```bash
cd /job/event_handler
npm install
```

## 2. Create .env File
```bash
cd /job/event_handler
cp .env.example .env
# Then edit .env with your credentials
```

## 3. Start Event Handler
```bash
cd /job/event_handler
nohup node server.js > /tmp/event-handler.log 2>&1 &
echo $! > /tmp/event-handler.pid
```

## 4. Verify It's Running
```bash
# Check process
ps aux | grep "node.*server.js" | grep -v grep

# Check port
netstat -tlnp | grep :3000

# Check logs
tail -f /tmp/event-handler.log
```

## 5. Configure Telegram Webhook (if using ngrok)
```bash
# Start ngrok in another terminal
ngrok http 3000

# Get the URL and set webhook
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -d "url=${NGROK_URL}/telegram/webhook"

# Verify
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo" | jq .
```

## 6. Test Webhook
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"update_id":999,"message":{"text":"test"}}' \
  http://localhost:3000/telegram/webhook
```

## Success Criteria
✅ Port 3000 listening
✅ Webhook responds 200 OK
✅ Telegram webhook URL matches your tunnel
✅ No errors in event-handler.log

## Model Configuration
**Current setup is OPTIMAL - no changes needed:**
- Chat: `claude-haiku-4-20250514` (cost-effective)
- Summaries: `claude-sonnet-4-20250514` (quality)
- Both support web_search_20250305

## Troubleshooting
- **Dependencies fail:** Make sure you're in `/job/event_handler` directory
- **Port already in use:** Kill existing process: `pkill -f "node.*server.js"`
- **Webhook errors:** Check TELEGRAM_BOT_TOKEN is correct
- **Can't reach webhook:** Make sure ngrok is running and URL is current

## Files Reference
- Setup instructions: `self-check-report.md` (comprehensive)
- Summary: `SUMMARY.md` (quick overview)
- This guide: `QUICK_START.md` (you are here)
