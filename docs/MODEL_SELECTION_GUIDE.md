# Model Selection Quick Reference

**TL;DR:** Use Ollama (free) for simple tasks, Haiku ($) for most work, Sonnet ($$) for complex jobs.

---

## Decision Tree

```
┌─────────────────────────────────────────┐
│  Does the task need LLM reasoning?      │
└──────┬──────────────────────────────────┘
       │
       ├─ NO ──► Use type: "command" (shell script)
       │         Cost: $0
       │
       └─ YES
          │
          ┌─────────────────────────────────────────┐
          │ Can it be done with a simple local LLM? │
          └──────┬──────────────────────────────────┘
                 │
                 ├─ YES ──► Use Ollama (qwen2.5:0.5b or llama3.2:3b)
                 │          Cost: $0
                 │          Examples: health checks, log summaries,
                 │                    simple classifications
                 │
                 └─ NO (needs Anthropic API)
                    │
                    ┌─────────────────────────────────────────┐
                    │  Is it a complex multi-step reasoning   │
                    │  task or critical production code?      │
                    └──────┬──────────────────────────────────┘
                           │
                           ├─ NO ──► Use Haiku
                           │         Cost: $0.10-0.50 per job
                           │         Examples: chat, simple code,
                           │                   docs, file ops
                           │
                           └─ YES ──► Use Sonnet (or Opus for critical)
                                      Cost: $0.40-2.00 per job (Sonnet)
                                            $2.00-10.00 per job (Opus)
                                      Examples: refactoring, security,
                                                architecture, research
```

---

## Model Comparison

| Model | Cost | Speed | Intelligence | Best For |
|-------|------|-------|--------------|----------|
| **Ollama (qwen2.5:0.5b)** | Free | ⚡⚡⚡ | ★☆☆ | Health checks, simple text tasks |
| **Ollama (llama3.2:3b)** | Free | ⚡⚡☆ | ★★☆ | Code formatting, basic summaries |
| **Claude Haiku 4** | $ | ⚡⚡⚡ | ★★★ | Chat, simple code, documentation |
| **Claude Sonnet 4** | $$ | ⚡⚡☆ | ★★★★ | Complex code, refactoring, research |
| **Claude Opus 4** | $$$ | ⚡☆☆ | ★★★★★ | Critical production, architecture |

---

## Cost Examples (as of Feb 2025)

### Monthly Scenarios

#### **Hobby Bot (Light Usage)**
- 10 Telegram messages/day (Haiku) = $3/month
- 48 heartbeats/day (Ollama) = $0/month
- 2 agent jobs/day (Haiku) = $12/month
- **Total: ~$15/month**

#### **Development Bot (Moderate Usage)**
- 30 Telegram messages/day (Haiku) = $9/month
- 48 heartbeats/day (Ollama) = $0/month
- 5 agent jobs/day (3 Haiku, 2 Sonnet) = $75/month
- **Total: ~$85/month**

#### **Production Bot (Heavy Usage)**
- 100 Telegram messages/day (Haiku) = $30/month
- 48 heartbeats/day (Ollama) = $0/month
- 10 agent jobs/day (5 Haiku, 4 Sonnet, 1 Opus) = $180/month
- **Total: ~$210/month**

#### **Before Optimization (Baseline - All Sonnet)**
- 10 Telegram messages/day (Sonnet) = $12/month
- 48 heartbeats/day (Sonnet agent) = $36/month
- 2 agent jobs/day (Sonnet) = $48/month
- **Total: ~$95/month**

**Savings: $80/month (84% reduction)** for light usage

---

## Implementation Guide

### 1. Set Default Model (Haiku)

**Event Handler (Telegram chat):**
Already configured in `event_handler/claude/index.js` as `claude-haiku-4-20250514`

**Docker Agent (GitHub jobs):**
```bash
# In GitHub: Settings → Secrets and variables → Actions → Variables
# Add variable:
MODEL=claude-haiku-4-20250514
```

### 2. Use Ollama for Cron Jobs

Edit `operating_system/CRONS.json`:

```json
{
  "name": "my-simple-task",
  "schedule": "0 * * * *",
  "type": "command",
  "command": "bash event_handler/cron/my-ollama-script.sh",
  "enabled": true
}
```

Create `event_handler/cron/my-ollama-script.sh`:

```bash
#!/bin/bash
set -e

# Start Ollama if not running
pgrep -x "ollama" > /dev/null || (ollama serve > /dev/null 2>&1 &)
sleep 3

# Use the model
PROMPT="Your task description here"
RESULT=$(ollama run qwen2.5:0.5b "$PROMPT")
echo "$RESULT"
```

### 3. Override for Complex Jobs

**Via Telegram chat:**
```
@thepopebot use sonnet to refactor the auth system
```

**Via webhook:**
```bash
curl -X POST https://your-server.com/webhook \
  -H "x-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "job": "Refactor authentication system",
    "model": "claude-sonnet-4-5-20250929"
  }'
```

---

## When to Upgrade Models

### Haiku → Sonnet

Upgrade when you see:
- ❌ Incomplete or shallow code implementations
- ❌ Misunderstanding complex multi-step instructions
- ❌ Poor handling of edge cases
- ❌ Oversimplified architectural decisions

### Sonnet → Opus

Upgrade when you need:
- ✓ Maximum reliability for production deploys
- ✓ Advanced multi-file refactoring with deep context
- ✓ Complex research requiring extensive reasoning
- ✓ Mission-critical decisions where mistakes are costly

---

## Cost Monitoring

### 1. Anthropic Console
Visit https://console.anthropic.com/settings/usage to:
- View daily/monthly usage
- Set billing alerts
- Identify expensive jobs

### 2. Session Logs
Check token usage in job logs:
```bash
cat logs/<JOB_ID>/*.jsonl | jq '.usage'
```

### 3. GitHub Actions
Review workflow run times (longer runs = more tokens):
```
Settings → Actions → Workflow runs
```

---

## Tips for Reducing Costs

### ✓ Use Focused Job Descriptions
❌ "Review the entire codebase and fix anything you find"
✅ "Fix the login bug in src/auth.js (line 45)"

### ✓ Reference Files Instead of Inlining
❌ Put 1000-line instructions directly in CRONS.json
✅ `"job": "Read operating_system/MY_TASK.md and execute"`

### ✓ Break Large Jobs into Smaller Ones
❌ One giant refactoring job (10M tokens)
✅ 5 focused jobs (2M tokens each) = easier to cache, debug, and optimize

### ✓ Use command-type for Non-LLM Tasks
If it doesn't need AI, don't use AI:
- File operations: `cp`, `mv`, `tar`
- API calls: `curl`, `http`-type actions
- Data processing: `jq`, `awk`, shell scripts

### ✓ Enable Prompt Caching (Future)
When Anthropic adds support, system prompts (SOUL.md, etc.) will be cached, reducing costs by ~50% on repeated calls.

---

## Model IDs Reference

### Current Models (Feb 2025)

| Model | ID | Notes |
|-------|-----|-------|
| Haiku 4 | `claude-haiku-4-20250514` | Current default |
| Sonnet 4 | `claude-sonnet-4-20250514` | Standard version |
| Sonnet 4.5 | `claude-sonnet-4-5-20250929` | Extended thinking |
| Opus 4 | `claude-opus-4-20250514` | Maximum capability |

Check [Anthropic's model documentation](https://docs.anthropic.com/en/docs/about-claude/models) for latest versions.

---

**Bottom line:** Start with Haiku + Ollama. Only upgrade when you see quality issues. Your wallet will thank you.
