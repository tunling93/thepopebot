Autonomous End-to-End Self-Check: Telegram Webhook + Event Handler Verification & Auto-Fix

CONTEXT:
- GitHub repo klonerat lokalt
- TELEGRAM_BOT_TOKEN, ANTHROPIC_API_KEY, GH_TOKEN finns som env vars
- event_handler server ligger i event_handler/server.js
- ngrok kan köra lokalt men kanske inte är tillgängligt från job-miljön

ACCEPTANCE CRITERIA:
1. Webhook URL måste synkas: läs från Telegram API, jämför med ngrok public_url om tillgänglig
2. Modellval: välj BILLIGASTE modell från /v1/models som accepterar tool.type="web_search_20250305" - validera med test-anrop
3. Event handler startas med nohup/pm2/screen så den körs vidare efter sessionen
4. /telegram/webhook endpoint svara 200 snabbt på POST, fel loggas separat
5. Slut-rapport: STATUS PASS/FAIL, exakta kommandon körda, filer ändrade, diffs

STEPS:

=== PHASE 1: TELEGRAM WEBHOOK VERIFICATION ===

1. Läs Telegram webhook status
   - curl -s https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo | jq .
   - Spara url-värde i CURRENT_WEBHOOK_URL

2. Verifiera ngrok tunnel (försök, men fallback om inte nåbar)
   - curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | jq .tunnels[0].public_url
   - Spara i NGROK_URL (kan vara tom om ngrok API inte nåbar från job-miljön)
   - Om NGROK_URL tom: log "ngrok API not reachable from job environment (expected in CI/CD)"

3. Beräkna rätt webhook URL
   - Om NGROK_URL finns: EXPECTED_WEBHOOK_URL=${NGROK_URL}/telegram/webhook
   - Om NGROK_URL tom: prova om du kan hämta från environment eller skip webhook update

4. Jämför och uppdatera webhook om behövs
   - Om CURRENT_WEBHOOK_URL != EXPECTED_WEBHOOK_URL OCH NGROK_URL finns:
     * Uppdatera: curl -s -X POST https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook -d "url=${EXPECTED_WEBHOOK_URL}" | jq .
     * Log: "Webhook updated from [old] to [new]"
   - Om mismatch men NGROK_URL tom:
     * Log: "Cannot update webhook - ngrok API not reachable from job. Manual step required."
     * Return STATUS FAIL with reason

5. Testa webhook endpoint POST
   - Skapa test-payload: '{"update_id":999,"message":{"text":"self-check"}}'
   - POST: curl -s -X POST -H "Content-Type: application/json" -d '{"update_id":999}' "${EXPECTED_WEBHOOK_URL}" 2>&1
   - Verifiera 200 svar (acceptera {"ok":true} eller liknande snabb svar)
   - Spara responsetime

6. Re-check Telegram getWebhookInfo
   - curl -s https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo | jq .
   - Verifiera att last_error_message är null/tom

=== PHASE 2: MODEL VALIDATION & SELECTION ===

7. Hämta modellista från Anthropic API
   - curl -s https://api.anthropic.com/v1/models \
     -H "x-api-key: ${ANTHROPIC_API_KEY}" \
     -H "anthropic-version: 2023-06-01" | jq '.data[] | {id, created_at}' > /tmp/models.json
   - Log: "Found $(cat /tmp/models.json | jq -r '.id' | wc -l) models"

8. Verifiera web_search-stödjande modeller
   - Känd lista från dokumentation (uppdaterad 2025):
     * claude-opus-4-20250514 ✓
     * claude-opus-4-6 ✓
     * claude-sonnet-4-5-20250929 ✓
     * claude-sonnet-4-20250514 ✓
     * claude-haiku-4-5-20251001 ✓
     * claude-haiku-4-6 ✓
     * claude-3-haiku-20240307 ✗ (DOES NOT SUPPORT web_search_20250305)
   
9. Läs aktuell modell från environment
   - CURRENT_MODEL=${EVENT_HANDLER_MODEL:-"claude-haiku-4-20250514"} (eller från .env/config)
   - Försök även läsa från event_handler/claude/index.js eller operating_system/ config
   - Log: "Current model: ${CURRENT_MODEL}"

10. Testa aktuell modell för web_search_20250305 support
    - Gör ett test-API-anrop med web_search tool:
      curl -X POST https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "content-type: application/json" \
        -d '{
          "model": "'${CURRENT_MODEL}'",
          "max_tokens": 100,
          "tools": [{"type": "web_search_20250305", "name": "web_search"}],
          "messages": [{"role": "user", "content": "test"}]
        }' 2>&1 | tee /tmp/model_test.json
    
    - Om svar innehåller "tool_not_found" eller "unknown_tool_type": modellen stödjer INTE web_search
    - Om svar är 200 och innehåller "tools": modellen stödjer web_search ✓

11. Om aktuell modell INTE stödjer web_search: välj ny
    - Sortera stödda modeller efter pris (billigaste först):
      * claude-haiku-4-5-20251001 (billigaste, ~$1/$5 per M tokens)
      * claude-haiku-4-6 (om finns)
      * claude-sonnet-4-20250514 (~$3/$15)
      * claude-sonnet-4-5-20250929 (~$3/$15)
    - Välj: RECOMMENDED_MODEL="claude-haiku-4-5-20251001"
    - Validera rekommenderad modell med samma test-anrop
    - Log: "Selected model: ${RECOMMENDED_MODEL}"

12. Uppdatera configuration om modell ändrades
    - Sök efter modell-referens i:
      * event_handler/.env eller .env.local
      * event_handler/claude/index.js
      * operating_system/ config-filer
      * GitHub Actions variabler (workflow-files kan innehålla hardcoded model)
    
    - Uppdatera EVENT_HANDLER_MODEL=${RECOMMENDED_MODEL} var den är satt
    - Log vilka filer som ändrades

=== PHASE 3: EVENT HANDLER RESTART ===

13. Kontrollera om event_handler redan körs
    - ps aux | grep "node.*event_handler" | grep -v grep
    - Om process finns: kill -TERM <pid> && sleep 2 && kill -9 <pid> 2>/dev/null (graceful + force)
    - Log: "Killed existing process (if any)"

14. Starta event_handler så den stannar inte när job slutar
    - Prova denna ordning (första som funkar):
      * Option A: nohup node event_handler/server.js > /tmp/event-handler.log 2>&1 &
      * Option B: pm2 (om installerat): pm2 start event_handler/server.js --name event-handler
      * Option C: screen/tmux session: screen -dm -S event-handler node event_handler/server.js
    - Spara PID och metod
    - Wait 3 sec
    - Verifiera: curl -s http://localhost:3000/health 2>/dev/null || echo "checking port..." && netstat -tlnp 2>/dev/null | grep 3000

15. Verifiera event_handler lyssnar på :3000
    - netstat -tlnp 2>/dev/null | grep :3000 || ss -tlnp 2>/dev/null | grep :3000
    - Om lyssnar: STATUS_PORT_3000="LISTENING"
    - Om inte: STATUS_PORT_3000="FAIL - process not listening"
    - Log: "Port 3000 status: ${STATUS_PORT_3000}"

=== PHASE 4: FINAL REPORT & COMMIT ===

16. Sammanställ rapport
    - Create /tmp/self-check-report.md with:
      
      # Self-Check Report
      
      ## Telegram Webhook
      - Webhook URL before: [CURRENT_WEBHOOK_URL]
      - Webhook URL after: [NEW_WEBHOOK_URL if changed]
      - ngrok tunnel available: [YES/NO]
      - ngrok public URL: [NGROK_URL or "N/A - not reachable from job environment"]
      - Webhook POST test: [200 OK / FAIL]
      - Telegram last_error: [null / error message]
      
      ## Model Selection
      - Current model: [CURRENT_MODEL]
      - Supports web_search_20250305: [YES/NO with test result]
      - Recommended model: [RECOMMENDED_MODEL]
      - Model changed: [YES/NO]
      - Files modified: [list]
      
      ## Event Handler
      - Previous process killed: [YES/NO]
      - Restart method: [nohup/pm2/screen]
      - Process PID: [pid]
      - Port 3000 listening: [YES/NO]
      - Startup log: [first 20 lines of event-handler.log]
      
      ## Commands Executed
      [list of all curl/npm/git commands with outputs]
      
      ## File Changes (diffs)
      [unified diff format for each changed file]
      
      ## FINAL STATUS
      STATUS: [PASS / FAIL]
      
      If FAIL: [specific reason and what needs to be done manually]

17. Git commit & push
    - git add -A
    - git commit -m "thepopebot: self-check auto-fix - webhook sync, model validation, event-handler restart"
    - git push origin <current-branch>
    - Log: commit hash

18. Output final report
    - cat /tmp/self-check-report.md
    - Also save to logs/{JOB_ID}/self-check-report.md

ERROR HANDLING:
- ngrok API not reachable: Log as expected in job environment, FAIL webhook update if required
- Webhook POST fails: Log error, continue to model check (don't block)
- Model test fails: Try next model in list, log all failures
- Event handler won't start: Log stderr, return FAIL with debug info
- Port 3000 still not listening after restart: FAIL, show netstat output

SUCCESS CRITERIA:
✓ Telegram webhook URL matches ngrok URL (or documented if ngrok unavailable)
✓ Webhook endpoint responds 200 to POST
✓ Selected model is cheapest available with web_search support
✓ Model change committed if applicable
✓ Event handler running and listening on port 3000
✓ Process will continue after job ends (nohup/pm2/screen verified)
✓ Final report with all details and diffs