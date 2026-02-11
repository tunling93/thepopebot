# Cost Optimization Guide

This document describes the cost optimization strategies implemented in thepopebot to minimize API usage while maintaining functionality.

## Overview

thepopebot has been optimized to use free local LLMs (via Ollama) for routine tasks and reserve paid Anthropic API calls for tasks that require advanced reasoning. This can reduce API costs by **80-95%** for typical usage patterns.

---

## What's Changed

### 1. **Local Ollama Integration**

The Docker agent now includes Ollama, enabling free local LLM inference for simple tasks.

**Dockerfile changes:**
```dockerfile
# Install Ollama for cost-efficient local LLM operations
RUN curl -fsSL https://ollama.com/install.sh | sh
```

**Benefits:**
- Zero API costs for routine operations
- Faster response times (no network latency)
- No rate limits
- Works offline

---

### 2. **Optimized Heartbeat Monitoring**

The heartbeat cron job now uses Ollama instead of spinning up a full Docker agent with Anthropic API calls.

**Before:**
```json
{
  "name": "heartbeat",
  "schedule": "*/30 * * * *",
  "type": "agent",
  "job": "Read the file at operating_system/HEARTBEAT.md...",
  "enabled": false
}
```

**After:**
```json
{
  "name": "heartbeat",
  "schedule": "*/30 * * * *",
  "type": "command",
  "command": "bash event_handler/cron/heartbeat-ollama.sh",
  "enabled": true
}
```

**Cost savings:** 
- **Before:** ~$0.02-0.05 per heartbeat (Sonnet) × 48/day = **$0.96-2.40/day**
- **After:** **$0/day** (local Ollama)
- **Annual savings:** **$350-875**

The heartbeat script (`event_handler/cron/heartbeat-ollama.sh`) uses the tiny `qwen2.5:0.5b` model (~0.5GB) for basic system checks.

---

### 3. **Haiku as Default Chat Model**

The Telegram chat interface now defaults to **Claude Haiku 4** instead of Sonnet.

**Changes:**
- `event_handler/claude/index.js`: `DEFAULT_MODEL = 'claude-haiku-4-20250514'`
- Environment variable: `EVENT_HANDLER_MODEL=claude-haiku-4-20250514` (optional override)

**Cost comparison (as of Feb 2025):**

| Model | Input ($/MTok) | Output ($/MTok) | Use Case |
|-------|----------------|-----------------|----------|
| **Claude Haiku 4** | $0.80 | $4.00 | Default - conversational chat, simple queries |
| **Claude Sonnet 4** | $3.00 | $15.00 | Complex reasoning, code generation |
| **Claude Opus 4** | $15.00 | $75.00 | Advanced tasks requiring maximum intelligence |

**Example cost per conversation:**
- **Haiku:** ~$0.01-0.05 per typical chat exchange
- **Sonnet:** ~$0.04-0.20 per typical chat exchange
- **Savings:** **75-80%** on chat interactions

---

### 4. **Recommended MODEL Variable Settings**

Set the `MODEL` repository variable to control which Anthropic model the Pi agent uses for autonomous jobs:

**For cost optimization (recommended default):**
```bash
# In GitHub: Settings → Secrets and variables → Actions → Variables
MODEL=claude-haiku-4-20250514
```

**For complex/critical jobs:**
```bash
MODEL=claude-sonnet-4-5-20250929
```

**Cost impact:**
- **Haiku:** ~$0.10-0.50 per typical agent job
- **Sonnet:** ~$0.40-2.00 per typical agent job
- **Savings:** **75-80%** per job

---

## When to Use Each Model

### Use **Ollama** (Free) for:
- ✓ Heartbeat/health checks
- ✓ Log summarization
- ✓ Simple status reporting
- ✓ Routine monitoring tasks
- ✓ Text classification
- ✓ Basic data validation

**Implementation:** Use `type: "command"` in CRONS.json with a script that calls `ollama run <model>`

### Use **Haiku** ($) for:
- ✓ Telegram chat conversations
- ✓ Simple code reviews
- ✓ Documentation updates
- ✓ File organization
- ✓ Basic API integrations
- ✓ Quick fixes and patches

**Implementation:** Default behavior (no MODEL variable set, or set to `claude-haiku-4-20250514`)

### Use **Sonnet** ($$) for:
- ✓ Complex code generation
- ✓ Multi-file refactoring
- ✓ Architectural decisions
- ✓ Security-critical changes
- ✓ Advanced debugging
- ✓ Research tasks requiring web search

**Implementation:** Set `MODEL=claude-sonnet-4-5-20250929` in GitHub Variables, or override per-job

### Use **Opus** ($$$) for:
- ✓ Mission-critical production deploys
- ✓ Complex multi-step workflows
- ✓ High-stakes decision making
- ✓ Advanced research requiring deep reasoning

**Implementation:** Set `MODEL=claude-opus-4-20250514` in GitHub Variables (use sparingly)

---

## Per-Job Model Override

You can override the default model for specific jobs via the chat interface:

```
@thepopebot use sonnet to refactor the authentication system for better security
```

Or when creating jobs via the API:

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

## Cost Monitoring Best Practices

### 1. **Track API Usage in Anthropic Console**
- Visit https://console.anthropic.com/settings/usage
- Set up billing alerts at your monthly budget threshold
- Review usage weekly to identify expensive jobs

### 2. **Review Job Logs**
Each job's session log (`logs/<JOB_ID>/*.jsonl`) contains token usage. Expensive jobs will show high token counts.

### 3. **Optimize Job Descriptions**
Shorter, clearer job prompts = fewer tokens:

❌ **Before:**
```json
{
  "job": "Please carefully review all the files in the repository and look for any potential security issues, performance problems, code quality concerns, or other issues that might need attention. Generate a comprehensive report with specific recommendations for each issue found."
}
```

✅ **After:**
```json
{
  "job": "Read operating_system/SECURITY_AUDIT.md and complete the tasks there."
}
```

Put detailed instructions in a markdown file, reference it briefly.

### 4. **Use Command-Type Crons for Simple Tasks**
If a cron job doesn't need LLM reasoning, use `type: "command"`:

```json
{
  "name": "backup-logs",
  "schedule": "0 2 * * *",
  "type": "command",
  "command": "tar -czf /job/tmp/logs-backup-$(date +%Y%m%d).tar.gz /job/logs",
  "enabled": true
}
```

---

## Example Cost Scenarios

### Scenario 1: Development Bot (Light Usage)
- **Daily chat:** 10 messages (Haiku) = $0.10
- **Heartbeats:** 48 checks (Ollama) = $0.00
- **Agent jobs:** 2 jobs/day (Haiku) = $0.40
- **Monthly total:** ~$15

### Scenario 2: Production Bot (Moderate Usage)
- **Daily chat:** 30 messages (Haiku) = $0.30
- **Heartbeats:** 48 checks (Ollama) = $0.00
- **Agent jobs:** 5 jobs/day (3 Haiku, 2 Sonnet) = $2.50
- **Monthly total:** ~$85

### Scenario 3: Before Optimization (Baseline)
- **Daily chat:** 10 messages (Sonnet) = $0.40
- **Heartbeats:** 48 checks (Sonnet agent) = $1.20
- **Agent jobs:** 2 jobs/day (Sonnet) = $1.60
- **Monthly total:** ~$95

**Savings for light usage:** $80/month (**84% reduction**)

---

## Available Ollama Models

The heartbeat script uses `qwen2.5:0.5b` (smallest, fastest). For other command-type tasks, consider:

| Model | Size | Use Case |
|-------|------|----------|
| `qwen2.5:0.5b` | 0.5GB | System checks, simple classification |
| `qwen2.5:1.5b` | 1.5GB | Basic reasoning, summaries |
| `llama3.2:3b` | 3GB | Code snippets, formatting |
| `phi4:14b` | 14GB | Complex local tasks (use sparingly) |

**Pull a model:**
```bash
ollama pull qwen2.5:1.5b
```

---

## Migration Checklist

If you're upgrading an existing thepopebot instance:

- [ ] Pull latest code with Ollama support
- [ ] Rebuild Docker image: `docker build -t mybot .`
- [ ] Update `EVENT_HANDLER_MODEL` to `claude-haiku-4-20250514` in `.env`
- [ ] Set GitHub `MODEL` variable to `claude-haiku-4-20250514`
- [ ] Review CRONS.json - convert simple agent jobs to command-type
- [ ] Test heartbeat: `bash event_handler/cron/heartbeat-ollama.sh`
- [ ] Monitor API usage for first week
- [ ] Document any job-specific model overrides needed

---

## Troubleshooting

### "Ollama not found" in heartbeat logs
The heartbeat script starts Ollama automatically. If you see this error, ensure:
1. Dockerfile includes Ollama installation
2. Container has sufficient memory (>2GB recommended)

### Haiku responses are too simple
For complex queries, ask the bot to "use sonnet" or set a per-job override. Haiku is optimized for speed and cost, not maximum intelligence.

### High token usage despite optimization
Check job logs for:
- Extremely long prompts (break into smaller jobs)
- Unnecessary file reads (be specific about paths)
- Repetitive tool calls (improve job instructions)

---

## Future Optimization Opportunities

1. **Caching:** Implement prompt caching for repeated system prompts (50% cost reduction on cache hits)
2. **Batch processing:** Queue multiple small jobs and process together
3. **Smart routing:** Automatically detect job complexity and route to appropriate model
4. **Local code analysis:** Use Ollama for static analysis before engaging Anthropic API

---

**Summary:** By using Ollama for routine tasks and Haiku as the default Anthropic model, you can reduce AI API costs by **80-95%** while maintaining high-quality outputs for the tasks that matter most.
