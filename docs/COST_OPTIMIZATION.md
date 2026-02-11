# Cost Optimization Guide

thepopebot is designed to minimize AI API costs through intelligent model selection and local LLM usage.

---

## Cost Breakdown

### Anthropic API Pricing (as of Feb 2025)

| Model | Input (per MTok) | Output (per MTok) | Speed | Use Case |
|-------|------------------|-------------------|-------|----------|
| **Claude Haiku 4** | $0.40 | $2.00 | Fast | Routine tasks, chat, simple jobs |
| **Claude Sonnet 4** | $3.00 | $15.00 | Medium | Complex reasoning, code generation |
| **Claude Opus 4** | $15.00 | $75.00 | Slow | Critical tasks requiring maximum intelligence |

**Cost multiplier:** Sonnet costs **7.5x more** than Haiku for input, **7.5x more** for output.

### GitHub Actions

| Plan | Free Minutes/Month | Cost After Free |
|------|-------------------|-----------------|
| **Public repos** | Unlimited | Free |
| **Private repos (Free plan)** | 2,000 | $0.008/minute |
| **Private repos (Pro plan)** | 3,000 | $0.008/minute |

**thepopebot uses ~2-5 minutes per job** (clone, run agent, commit, PR).

---

## Three-Tier Cost Strategy

thepopebot implements a three-tier approach to minimize costs:

### 1. **Zero Cost: Ollama for Heartbeats**

**What:** Local LLM running inside the Docker agent (no API calls)  
**Model:** `qwen2.5:0.5b` (~400MB, blazing fast)  
**Use:** Health checks, system monitoring, simple status updates  
**Cost:** **$0.00** - Runs locally, no external API

The heartbeat cron runs every 30 minutes using Ollama instead of spinning up a full agent job. This eliminates ~48 API calls per day that would cost real money with Haiku or Sonnet.

**Configured in:** `operating_system/CRONS.json`
```json
{
  "name": "heartbeat",
  "schedule": "*/30 * * * *",
  "type": "command",
  "command": "bash event_handler/cron/heartbeat.sh",
  "enabled": true
}
```

### 2. **Low Cost: Haiku for Routine Tasks**

**What:** Claude Haiku 4 via Anthropic API  
**Model:** `claude-haiku-4-20250514`  
**Use:** 
- Telegram chat conversations
- Simple file operations
- Git commands
- Text processing
- Daily scheduled checks
- Most agent jobs

**Cost:** ~$0.01-0.05 per typical job (assuming ~10K input tokens, 5K output)

**Set as default:**
- Event Handler: Already configured in `event_handler/claude/index.js`
- Docker Agent: Set `MODEL` variable to `claude-haiku-4-20250514` in GitHub Settings

### 3. **High Cost: Sonnet for Complex Work**

**What:** Claude Sonnet 4 via Anthropic API  
**Model:** `claude-sonnet-4-20250514`  
**Use:**
- Complex code refactoring
- Multi-file changes
- Deep reasoning tasks
- Critical operations
- Self-modification jobs

**Cost:** ~$0.10-0.40 per typical job (same token counts as above)

**When to use:** Explicitly request in job description or override `MODEL` variable for specific workflows.

---

## How to Configure

### 1. Set Default Model (Recommended: Haiku)

**In GitHub Repository Variables:**

1. Go to **Settings → Secrets and variables → Actions → Variables**
2. Click **New repository variable**
3. Name: `MODEL`
4. Value: `claude-haiku-4-20250514`
5. Click **Add variable**

This sets Haiku as the default for all Docker agent jobs.

### 2. Event Handler Chat (Already Configured)

The Telegram chat uses Haiku by default. To override:

**In `event_handler/.env`:**
```bash
EVENT_HANDLER_MODEL=claude-sonnet-4-20250514  # Use Sonnet for chat
```

Or leave unset to use the default (`claude-haiku-4-20250514`).

### 3. Per-Job Model Override

You can specify a different model for specific jobs by including it in the job description:

**Via Telegram:**
```
Create a job using Sonnet: Review the entire codebase and suggest architectural improvements
```

The agent will see this instruction and the model switcher logic can be implemented in the job creation flow.

**Via CRONS.json:**
```json
{
  "name": "complex-analysis",
  "schedule": "0 0 * * 0",
  "type": "agent",
  "job": "Using claude-sonnet-4-20250514: Analyze code quality across all repositories",
  "enabled": true
}
```

---

## Switching Logic

### Automatic Model Selection (Future Enhancement)

You can implement automatic model selection based on job complexity:

**In `event_handler/tools/create-job.js`:**

1. Analyze job description length and keywords
2. If job contains "complex", "refactor", "architecture" → use Sonnet
3. If job is short and simple → use Haiku
4. If job is heartbeat/monitor → use Ollama command

**Keyword triggers for Sonnet:**
- "complex", "refactor", "architecture"
- "entire codebase", "all files"
- "deep analysis", "critical"
- File count > 10 or character count > 2000

**Keyword triggers for Haiku:**
- "simple", "quick", "check"
- "update", "add", "remove" (single operations)
- File count < 5 and character count < 500

### Manual Override Workflow

**Option 1: Job Description Prefix**
```
[SONNET] Review the codebase architecture and suggest improvements
[HAIKU] Update the README with today's date
[OLLAMA] Check system health and log status
```

**Option 2: Telegram Command**
```
/job-sonnet Review the codebase architecture
/job-haiku Update the README with today's date
```

Implement these commands in `event_handler/server.js` Telegram handler.

---

## Cost Estimates

### Typical Monthly Usage (Private Repo)

**Setup:**
- 100 chat messages (Telegram) → 100K tokens → **$0.20** (Haiku)
- 30 simple jobs (updates, checks) → 500K tokens → **$1.00** (Haiku)
- 10 complex jobs (refactors, analysis) → 500K tokens → **$7.50** (Sonnet)
- 1,440 heartbeats (30min intervals) → **$0.00** (Ollama)
- GitHub Actions: 200 minutes used → **Free** (within 2,000/month limit)

**Total: ~$8.70/month**

### Without Cost Optimization (All Sonnet + No Ollama)

Same usage but everything uses Sonnet:
- 100 chat messages → **$1.50**
- 30 simple jobs → **$7.50**
- 10 complex jobs → **$7.50**
- 1,440 heartbeats → **$10.80** (if agent-type, not command)

**Total: ~$27.30/month**

**Savings: $18.60/month (68% reduction)**

---

## Ollama Integration Details

### How It Works

1. **Dockerfile** installs Ollama during image build
2. **heartbeat.sh** script starts Ollama service on first run
3. Pulls lightweight model (`qwen2.5:0.5b`) if not cached
4. Runs health check with 10-second timeout
5. Returns HEALTHY/UNHEALTHY status

### Available Models

Ollama supports hundreds of models. Recommended for heartbeats:

| Model | Size | Speed | Capability |
|-------|------|-------|------------|
| `qwen2.5:0.5b` | 400MB | Instant | Basic text, perfect for health checks |
| `qwen2.5:1.5b` | 900MB | Very fast | Better reasoning, still lightweight |
| `llama3.2:1b` | 1.3GB | Very fast | Good balance |
| `phi3:mini` | 2.3GB | Fast | Production-ready for simple tasks |

**To change model:** Edit `event_handler/cron/heartbeat.sh` and set `MODEL` variable.

### When NOT to Use Ollama

- Complex reasoning tasks
- Code generation
- Multi-step problem solving
- Production-critical operations

Ollama is perfect for "is the system alive?" checks, not "fix this complex bug."

---

## Migration Checklist

If you're upgrading from an older thepopebot version:

- [ ] Update Dockerfile (Ollama installation added)
- [ ] Update `operating_system/CRONS.json` (heartbeat changed to command-type)
- [ ] Set `MODEL` variable to `claude-haiku-4-20250514` in GitHub
- [ ] Verify `EVENT_HANDLER_MODEL` defaults to Haiku in `event_handler/claude/index.js`
- [ ] Make `event_handler/cron/heartbeat.sh` executable: `chmod +x event_handler/cron/heartbeat.sh`
- [ ] Test heartbeat: `bash event_handler/cron/heartbeat.sh`
- [ ] Rebuild Docker image (if using custom IMAGE_URL)

---

## Monitoring Costs

### Anthropic Console

Track API usage in real-time:
- [Anthropic Console](https://console.anthropic.com) → Usage tab
- Set up billing alerts for cost thresholds
- Review token usage by model

### GitHub Actions

Monitor compute usage:
- Repo → Settings → Actions → Usage
- Shows minutes used vs. limit
- Alerts before hitting limit (private repos only)

---

## FAQ

**Q: Can I use Opus for jobs?**  
A: Yes, but it's 37.5x more expensive than Haiku for output tokens. Only use for critical, high-stakes work.

**Q: Does Ollama work on the Event Handler?**  
A: The heartbeat script checks if Ollama is available. It works in Docker agent but gracefully skips on Event Handler (which doesn't need it).

**Q: Can I use Ollama for full agent jobs?**  
A: Not currently. Pi coding agent requires Anthropic API. Ollama is only used for command-type crons where no deep reasoning is needed.

**Q: What if I want ALL jobs to use Sonnet?**  
A: Set `MODEL` variable to `claude-sonnet-4-20250514`. But this will cost 7.5x more—make sure you need that extra intelligence.

**Q: How much does the heartbeat save?**  
A: At 48 runs/day with Haiku (~2K tokens each), you'd spend ~$0.08/day = $2.40/month. With Ollama: **$0.00/month**.

**Q: Can I use other local LLMs instead of Ollama?**  
A: Yes! Edit `heartbeat.sh` to use LM Studio, llama.cpp, or any other local inference engine. The principle is the same: zero API cost.

---

## Summary

**Default Configuration (Recommended):**
- ✅ Event Handler chat: Haiku
- ✅ Docker agent jobs: Haiku
- ✅ Heartbeats: Ollama (free)
- ⚠️ Override to Sonnet only when needed

**Expected Savings:** 60-80% cost reduction vs. all-Sonnet setup

**Trade-offs:** Haiku is fast and good enough for 90% of tasks. Use Sonnet when you truly need the extra reasoning power.

**Bottom line:** thepopebot lets you run an autonomous agent for **<$10/month** instead of $30-50/month with other frameworks.
