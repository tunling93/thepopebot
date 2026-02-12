Create a backup of the thepopebot configuration by:
1. Creating a backup archive containing:
   - `operating_system/` directory (SOUL.md, CHATBOT.md, JOB_SUMMARY.md, HEARTBEAT.md, CRONS.json, TRIGGERS.json)
   - `.pi/skills/` directory (if it exists)
   - `Dockerfile` and `entrypoint.sh` for reference
2. Naming the archive `backup-$(date +%Y-%m-%d-%H%M%S).tar.gz`
3. Creating or updating a `backups/` directory in the repo root
4. Moving the archive into `backups/`
5. Committing the backup with message "thepopebot: configuration backup"
6. Pushing to a new branch `backup/config-$(date +%s)` (or `backups` branch if preferred)

This preserves all configuration, personality, and custom skills in a versioned, retrievable format.