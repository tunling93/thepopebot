# thepopebot

**Autonomous AI agents. All the power. None of the leaked API keys.**

---

## Why thepopebot?

**Secure by default** — Other frameworks hand credentials to the LLM and hope for the best. thepopebot is different: the AI literally cannot access your secrets, even if it tries. Secrets are filtered at the process level before the agent's shell even starts.

**Cost-optimized by default** — Runs on **Claude Haiku 4** for 80-85% lower costs than Sonnet-based agents. Smart escalation: the agent automatically detects when complex tasks need Sonnet and asks permission before switching. Most tasks run on Haiku (<$0.05/job), heartbeats use free local Ollama ($0.00), and Sonnet is reserved only for critical work. **Typical monthly cost: <$10 instead of $30-50+**. See [Cost Optimization Guide](docs/COST_OPTIMIZATION.md) for details.

**The repository IS the agent** — Every action your agent takes is a git commit. You can see exactly what it did, when, and why. If it screws up, revert it. Want to clone your agent? Fork the repo — code, personality, scheduled jobs, full history, all of it goes with your fork.

**Free compute, built in** — Every GitHub account comes with free cloud computing time. thepopebot uses that to run your agent. One task or a hundred in parallel — the compute is already included.

**Self-evolving** — The agent modifies its own code through pull requests. Every change is auditable, every change is reversible. You stay in control.

---

## How It Works

```
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│  ┌─────────────────┐         ┌─────────────────┐                     │
│  │  Event Handler  │ ──1──►  │     GitHub      │                     │
│  │  (creates job)  │         │ (job/* branch)  │                     │
│  └────────▲────────┘         └────────┬────────┘                     │
│           │                           │                              │
│           │                           2 (triggers run-job.yml)    │
│           │                           │                              │
│           │                           ▼                              │
│           │                  ┌─────────────────┐                     │
│           │                  │  Docker Agent   │                     │
│           │                  │  (runs Pi, PRs) │                     │
│           │                  └────────┬────────┘                     │
│           │                           │                              │
│           │                           3 (creates PR)                 │
│           │                           │                              │
│           │                           ▼                              │
│           │                  ┌─────────────────┐                     │
│           │                  │     GitHub      │                     │
│           │                  │   (PR opened)   │                     │
│           │                  └────────┬────────┘                     │
│           │                           │                              │
│           │                           4a (auto-merge.yml)            │
│           │                           4b (update-event-handler.yml)  │
│           │                           │                              │
│           5 (Telegram notification)   │                              │
│           └───────────────────────────┘                              │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

You talk to your bot on Telegram (or hit a webhook). The Event Handler creates a job branch. GitHub Actions spins up a Docker container with the Pi coding agent. The agent does the work, commits the results, and opens a PR. Auto-merge handles the rest. You get a Telegram notification when it's done.

---

## Get FREE server time on Github!

| | thepopebot | Other platforms |
|---|---|---|
| **Public repos** | Free. $0. GitHub Actions doesn't charge. | $20-100+/month |
| **Private repos** | 2,000 free minutes/month (every GitHub plan, including free) | $20-100+/month |
| **Infrastructure** | GitHub Actions (already included) | Dedicated servers |

You just bring your own [Anthropic API key](https://console.anthropic.com/).

---

## Get Started

### Prerequisites

| Requirement | Install |
|-------------|---------|
| **Node.js 18+** | [nodejs.org](https://nodejs.org) |
| **npm** | Included with Node.js |
| **Git** | [git-scm.com](https://git-scm.com) |
| **GitHub CLI** | [cli.github.com](https://cli.github.com) |
| **ngrok*** | [ngrok.com](https://ngrok.com/download) |

*\*ngrok is only required for local development. Production deployments don't need it.*

### Three steps

**Step 1** — Fork this repository:

[![Fork this repo](https://img.shields.io/badge/Fork_this_repo-238636?style=for-the-badge&logo=github&logoColor=white)](https://github.com/stephengpope/thepopebot/fork)

> GitHub Actions are disabled by default on forks. Go to the **Actions** tab in your fork and enable them.

**Step 2** — Clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/thepopebot.git
cd thepopebot
```

**Step 3** — Run the setup wizard:

```bash
npm run setup
```

The wizard handles everything:
- Checks prerequisites (Node.js, Git, GitHub CLI, ngrok)
- Creates a GitHub Personal Access Token
- Collects API keys (Anthropic required; OpenAI, Groq, and [Brave Search](https://api-dashboard.search.brave.com/app/keys) optional)
- Sets GitHub repository secrets and variables
- Sets up Telegram bot
- Starts the server + ngrok, generates `event_handler/.env`
- Registers webhooks and verifies everything works

**After setup, message your Telegram bot to create jobs!**

---

## Cost Optimization & Model Selection

thepopebot is **cost-optimized by default** using **Claude Haiku 4** for all operations. This provides 80-85% cost savings compared to Sonnet while maintaining excellent performance for routine tasks.

### Default Configuration (Already Set Up)

| Component | Model | Cost per Job | Use Case |
|-----------|-------|--------------|----------|
| **Telegram Chat** | Haiku | ~$0.01 | Conversations, planning, job creation |
| **Agent Jobs** | Haiku | ~$0.01-0.05 | Most autonomous tasks |
| **Heartbeats** | Ollama (free) | $0.00 | System monitoring |

**Estimated monthly cost: <$10** for typical usage (100 chat messages, 30 jobs, 1440 heartbeats)

### Smart Escalation

The agent **automatically detects** when tasks require more intelligence and will:
1. Stop execution
2. Explain why Sonnet is needed
3. Provide cost estimate
4. Wait for your approval before proceeding

**Tasks that require Sonnet:**
- Complex architecture design or refactoring
- Multi-file changes (10+ files)
- Critical security or deployment changes
- Advanced debugging or performance optimization

**Tasks Haiku handles well:**
- Single-file code changes
- Documentation updates
- Simple bug fixes
- Configuration changes
- Web scraping and data processing
- Routine maintenance

### How to Switch Models

**For a specific job** (Telegram):
```
Create a job using Sonnet: [your task description]
```

**For all future jobs** (GitHub repository settings):
1. Go to **Settings → Secrets and variables → Actions → Variables**
2. Find or create `MODEL` variable
3. Change value to:
   - `claude-haiku-4-20250514` (default, cost-optimized)
   - `claude-sonnet-4-20250514` (7.5x more expensive, more capable)

**For chat** (Event Handler `.env` file):
```bash
EVENT_HANDLER_MODEL=claude-sonnet-4-20250514  # Override to Sonnet
```

### Cost Comparison

| Model | Input Cost (per 1M tokens) | Output Cost (per 1M tokens) | When to Use |
|-------|----------------------------|------------------------------|-------------|
| **Haiku** | $0.40 | $2.00 | Default for 90% of tasks |
| **Sonnet** | $3.00 | $15.00 | Complex work only (7.5x more expensive) |
| **Opus** | $15.00 | $75.00 | Critical tasks only (37.5x more expensive) |

💡 **Pro tip:** Keep Haiku as default. Let the agent tell you when it needs Sonnet. This maximizes cost savings without sacrificing quality.

---

## Docs

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | Two-layer design, file structure, API endpoints, GitHub Actions, Docker agent |
| [Configuration](docs/CONFIGURATION.md) | Environment variables, GitHub secrets, repo variables, ngrok, Telegram setup |
| [Customization](docs/CUSTOMIZATION.md) | Personality, skills, operating system files, using your bot, security details |
| [Cost Optimization](docs/COST_OPTIMIZATION.md) | **Save 80-85% on API costs** — Haiku by default, smart escalation, Ollama integration |
| [Cost Optimization Migration](docs/COST_OPTIMIZATION_MIGRATION.md) | **Upgrade guide** — Migrate existing installations to cost-optimized Haiku configuration |
| [Model Selection Quick Reference](docs/MODEL_SELECTION_QUICK_REFERENCE.md) | **One-page cheat sheet** — When to use Haiku vs Sonnet vs Opus, costs, examples |
| [Auto-Merge](docs/AUTO_MERGE.md) | Auto-merge controls, ALLOWED_PATHS configuration |
| [How to Use Pi](docs/HOW_TO_USE_PI.md) | Guide to the Pi coding agent |
| [Security](docs/SECURITY_TODO.md) | Security hardening plan |
