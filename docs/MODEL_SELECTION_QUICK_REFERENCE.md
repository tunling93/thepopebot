# Model Selection Quick Reference

**One-page guide for choosing the right model**

---

## 🎯 Default Configuration (Cost-Optimized)

| Component | Model | Cost | Speed |
|-----------|-------|------|-------|
| Telegram Chat | Haiku | $0.01/conversation | Fast ⚡ |
| Agent Jobs | Haiku | $0.01-0.05/job | Fast ⚡ |
| Heartbeats | Ollama | Free | Instant ⚡⚡ |

**Monthly Cost:** <$10 for typical usage

---

## 💰 Cost Comparison

| Model | Input ($/MTok) | Output ($/MTok) | Speed | When to Use |
|-------|----------------|-----------------|-------|-------------|
| **Haiku** | $0.40 | $2.00 | Fast | 90% of tasks |
| **Sonnet** | $3.00 | $15.00 | Medium | Complex work |
| **Opus** | $15.00 | $75.00 | Slow | Critical only |

**Multipliers:** Sonnet = 7.5x Haiku, Opus = 37.5x Haiku

---

## ✅ Use Haiku For (90% of tasks)

- Single-file code changes
- Documentation updates
- Simple bug fixes
- Configuration files
- Git operations (commit, PR, merge)
- File operations (read, write, move)
- Web scraping & data extraction
- Text processing & formatting
- Running commands
- Simple scripts

**Cost:** $0.01-0.05 per task

---

## ⚠️ Use Sonnet For (10% of tasks)

- Complex architecture design
- Multi-file refactorings (10+ files)
- Security-sensitive changes
- Performance optimization
- Advanced debugging
- Codebase-wide changes
- Breaking changes with migration
- Deep algorithm analysis

**Cost:** $0.10-0.40 per task

---

## 🚨 Use Opus For (1% of tasks)

- Mission-critical security audits
- Production deployment failures
- Complex distributed system issues
- High-stakes legal/compliance work

**Cost:** $1.00-2.00 per task

---

## 🔄 How to Switch Models

### Via Telegram (One Job)

```
Create a job using Sonnet: [task description]
```

### Via GitHub Variable (All Jobs)

1. Settings → Secrets and variables → Actions → Variables
2. Edit `MODEL` variable
3. Set to:
   - `claude-haiku-4-20250514` (default)
   - `claude-sonnet-4-20250514` (expensive)
   - `claude-opus-4-20250514` (very expensive)

### Via Event Handler .env (Chat)

```bash
EVENT_HANDLER_MODEL=claude-sonnet-4-20250514
```

---

## 🤖 Smart Escalation

**The agent automatically detects when it needs Sonnet:**

1. Agent encounters complex task
2. Agent stops and explains why Sonnet is needed
3. Agent shows cost estimate
4. Agent waits for your approval
5. You decide: proceed with Sonnet or try with Haiku

**Example:**
```
⚠️ This task requires Sonnet-level intelligence:

Refactoring 15 files with complex interdependencies.
Haiku may miss subtle bugs.

Cost Impact: $0.30 (vs $0.04 with Haiku)

Approve to proceed with Sonnet? (yes/no)
```

---

## 💡 Pro Tips

### Maximize Savings

1. **Let the agent decide** — It knows when it needs Sonnet
2. **Start with Haiku** — Only upgrade if it fails
3. **Batch simple tasks** — Multiple Haiku jobs cheaper than one Sonnet
4. **Use Ollama** — Free local LLM for heartbeats/monitoring

### When to Override

- **Use Sonnet from start** if:
  - Task is clearly complex (architecture, multi-file)
  - You've tried Haiku and it failed
  - Time is critical (Sonnet faster for complex tasks)

- **Never use Opus** unless:
  - Mission-critical production issue
  - Security vulnerability requiring deep analysis
  - You've already exhausted Sonnet

### Cost Monitoring

- **Anthropic Console:** Track usage by model
- **Session Logs:** Check `logs/{JOB_ID}/` for model used
- **Telegram Notifications:** Show model + cost estimate (future feature)

---

## 📊 Cost Examples

### Typical Job Costs

| Task | Tokens | Model | Cost |
|------|--------|-------|------|
| "Fix typo in README" | 5K | Haiku | $0.01 |
| "Add new feature to component" | 30K | Haiku | $0.06 |
| "Refactor authentication system" | 50K | Sonnet | $0.75 |
| "Analyze entire codebase security" | 100K | Sonnet | $1.50 |
| "Production incident analysis" | 100K | Opus | $7.50 |

### Monthly Budget Planning

| Usage Profile | Haiku | Sonnet | Opus | Total |
|---------------|-------|--------|------|-------|
| **Light** (20 jobs) | $0.50 | $0 | $0 | **$0.50** |
| **Medium** (50 jobs) | $2.00 | $3.00 | $0 | **$5.00** |
| **Heavy** (100 jobs) | $5.00 | $10.00 | $0 | **$15.00** |
| **Power** (200 jobs) | $10.00 | $20.00 | $5.00 | **$35.00** |

*Assumes 80% Haiku, 18% Sonnet, 2% Opus split*

---

## 🎯 Decision Tree

```
                    NEW TASK
                        │
                        ▼
            Is it routine/simple?
                   /        \
                 YES         NO
                  │           │
                  ▼           ▼
            Use Haiku    Complex enough
                         for Sonnet?
                           /      \
                         YES       NO
                          │         │
                          ▼         ▼
                     Use Sonnet  Try Haiku
                                     │
                                     ▼
                                 Failed?
                                   /   \
                                 YES    NO
                                  │     │
                                  ▼     ▼
                            Use Sonnet  Done!
```

---

## ⚙️ Configuration Files

| File | What It Controls |
|------|------------------|
| `event_handler/claude/index.js` | Chat model default (Haiku) |
| `event_handler/.env` | Override chat model |
| GitHub `MODEL` variable | Agent job default (Haiku) |
| `operating_system/SOUL.md` | Smart escalation logic |
| `setup/setup.mjs` | New installation defaults |

---

## 📞 Quick Commands

### Check Current Setup

```bash
# Verify configuration
bash tmp/verify-cost-optimization.sh

# Check GitHub MODEL variable
gh variable list | grep MODEL

# Check Event Handler default
grep DEFAULT_MODEL event_handler/claude/index.js
```

### Update Configuration

```bash
# Set MODEL to Haiku (recommended)
gh variable set MODEL --body "claude-haiku-4-20250514"

# Set MODEL to Sonnet (expensive)
gh variable set MODEL --body "claude-sonnet-4-20250514"

# Update Event Handler (in .env)
echo "EVENT_HANDLER_MODEL=claude-haiku-4-20250514" >> event_handler/.env
```

---

## ❓ FAQ

**Q: What if Haiku fails?**  
A: Agent will stop and ask permission to use Sonnet.

**Q: Can I force Sonnet for all jobs?**  
A: Yes, set `MODEL` variable to `claude-sonnet-4-20250514`. But costs will be 7.5x higher.

**Q: How do I know which model was used?**  
A: Check session logs in `logs/{JOB_ID}/` or Anthropic Console.

**Q: Is Haiku less intelligent?**  
A: For simple tasks, no difference. For complex reasoning, yes. Agent knows when to escalate.

**Q: What about Opus?**  
A: Only use for mission-critical work. It's 37.5x more expensive than Haiku.

---

## 📚 Full Documentation

- [Cost Optimization Guide](COST_OPTIMIZATION.md) — Detailed strategies
- [Migration Guide](COST_OPTIMIZATION_MIGRATION.md) — Upgrade from Sonnet
- [Configuration Guide](CONFIGURATION.md) — All settings explained

---

**Last Updated:** 2026-02-12  
**Version:** 1.0 (Cost-Optimized Release)

---

## 🎉 Remember

**Default = Haiku = Fast + Cheap + Smart Escalation**

Let the agent tell you when it needs more power. You stay in control of costs.
