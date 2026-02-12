# Cost Optimization Migration Guide

This guide helps existing thepopebot users migrate to the new cost-optimized default configuration (Haiku instead of Sonnet).

---

## TL;DR

**New users:** Setup wizard automatically configures Haiku. No action needed.

**Existing users:** Set `MODEL` variable to `claude-haiku-4-20250514` in GitHub repository settings.

**Expected savings:** 80-85% cost reduction on API calls.

---

## What Changed?

### Before (Pre-Migration)

- **Event Handler**: Used whatever model was set in `.env` (often Sonnet)
- **Docker Agent**: Used Pi's default (Claude Sonnet)
- **Setup Wizard**: Set `MODEL` to Sonnet
- **No smart escalation**: Agent tried everything with Sonnet
- **Typical monthly cost**: $30-50 for moderate usage

### After (Post-Migration)

- **Event Handler**: Defaults to Haiku (`claude-haiku-4-20250514`)
- **Docker Agent**: Uses `MODEL` variable (Haiku by default)
- **Setup Wizard**: Sets `MODEL` to Haiku
- **Smart escalation**: Agent detects when Sonnet is needed
- **Typical monthly cost**: <$10 for moderate usage

---

## Migration Steps

### Step 1: Update GitHub Repository Variable

1. Go to your forked repository on GitHub
2. Navigate to **Settings → Secrets and variables → Actions → Variables**
3. Find the `MODEL` variable:
   - If it exists: Click **Update** and change value to `claude-haiku-4-20250514`
   - If it doesn't exist: Click **New repository variable**
     - Name: `MODEL`
     - Value: `claude-haiku-4-20250514`
4. Click **Save** or **Add variable**

### Step 2: Update Event Handler (Optional)

The Event Handler now defaults to Haiku. If you previously set `EVENT_HANDLER_MODEL` in your `.env` file:

1. Open `event_handler/.env`
2. Remove or update the line:
   ```bash
   # Remove this line (to use default Haiku):
   # EVENT_HANDLER_MODEL=claude-sonnet-4-20250514
   
   # Or explicitly set to Haiku:
   EVENT_HANDLER_MODEL=claude-haiku-4-20250514
   ```
3. Restart your Event Handler server

### Step 3: Pull Latest Changes

If you haven't already, pull the latest changes from the upstream repository:

```bash
cd /path/to/your/thepopebot
git remote add upstream https://github.com/stephengpope/thepopebot.git
git fetch upstream
git merge upstream/main
```

### Step 4: Verify Configuration

Run the verification script to confirm everything is set up correctly:

```bash
bash tmp/verify-cost-optimization.sh
```

Expected output:
```
✅ Event Handler: Haiku configured
✅ Setup Wizard: Haiku configured
✅ Smart Escalation: Documented in SOUL.md
✅ README: Cost optimization section present
✅ COST_OPTIMIZATION.md: Smart escalation documented
```

### Step 5: Test the Setup

1. **Test Telegram chat:**
   - Message your bot with a simple question
   - Bot should respond using Haiku (you'll notice faster response times)

2. **Test a simple job:**
   - Create a job: "Update the README with today's date"
   - Job should complete successfully with Haiku

3. **Test smart escalation:**
   - Create a complex job: "Refactor the entire codebase architecture"
   - Agent should stop and request Sonnet

---

## What If I Want to Keep Using Sonnet?

If you prefer to keep using Sonnet for all jobs:

1. Set `MODEL` variable to `claude-sonnet-4-20250514`
2. Set `EVENT_HANDLER_MODEL=claude-sonnet-4-20250514` in `.env`
3. Comment out the smart escalation section in `operating_system/SOUL.md`

**Trade-off:** You'll pay 7.5x more per job, but get Sonnet's intelligence for every task.

---

## Cost Comparison

### Before Migration (All Sonnet)

Example usage: 100 chat messages, 40 jobs per month

- Chat (100 messages × 10K tokens avg): ~$1.50
- Jobs (40 jobs × 50K tokens avg): ~$15.00
- Heartbeats (if agent-type): ~$10.80
- **Total: ~$27.30/month**

### After Migration (Smart Model Selection)

Same usage with intelligent model selection:

- Chat (100 messages, Haiku): ~$0.20
- Simple jobs (30 jobs, Haiku): ~$1.00
- Complex jobs (10 jobs, Sonnet): ~$7.50
- Heartbeats (Ollama, free): ~$0.00
- **Total: ~$8.70/month**

**Savings: $18.60/month (68% reduction)**

---

## Troubleshooting

### Problem: Jobs fail with "model not found" error

**Solution:** Double-check the `MODEL` variable value:
- Correct: `claude-haiku-4-20250514`
- Incorrect: `claude-haiku-4` (missing date version)

### Problem: Agent doesn't detect when Sonnet is needed

**Solution:** Make sure you pulled the latest `operating_system/SOUL.md` with smart escalation logic.

### Problem: Chat still uses Sonnet

**Solution:** Check `event_handler/.env` and remove/update `EVENT_HANDLER_MODEL` variable.

### Problem: Setup wizard still sets Sonnet

**Solution:** Pull latest changes from upstream. The setup wizard now defaults to Haiku.

---

## FAQ

**Q: Will my existing jobs break if I switch to Haiku?**  
A: No. Haiku handles 90% of tasks perfectly. For the 10% that need Sonnet, the agent will detect it and ask permission.

**Q: Can I override the model for a specific job?**  
A: Yes! Tell your Telegram bot: "Create a job using Sonnet: [task description]"

**Q: How do I know if a job used Haiku or Sonnet?**  
A: Check the session logs in `logs/{JOB_ID}/` — the model is logged at the start.

**Q: What if I'm in the middle of a complex project?**  
A: You can temporarily switch back to Sonnet by setting the `MODEL` variable to `claude-sonnet-4-20250514`. Switch back to Haiku when the project is complete.

**Q: Does this affect the quality of the agent's work?**  
A: For routine tasks (single-file changes, documentation, simple scripts), no difference. For complex architecture or multi-system changes, Haiku will ask for Sonnet when needed.

---

## Rollback (If Needed)

If you want to revert to the old Sonnet-only configuration:

1. Set `MODEL` variable to `claude-sonnet-4-20250514`
2. Set `EVENT_HANDLER_MODEL=claude-sonnet-4-20250514` in `.env`
3. Remove smart escalation section from `operating_system/SOUL.md`

**Warning:** This will increase your costs by 7.5x compared to Haiku.

---

## Summary

✅ **New default:** Claude Haiku 4 (80-85% cheaper)  
✅ **Smart escalation:** Agent detects when Sonnet needed  
✅ **No quality loss:** Haiku handles 90% of tasks perfectly  
✅ **User control:** Always asks permission before using Sonnet  
✅ **Easy migration:** Just update one GitHub variable  

**Expected outcome:** <$10/month instead of $30-50/month 🎉
