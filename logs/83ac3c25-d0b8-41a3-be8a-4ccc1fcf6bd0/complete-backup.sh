#!/bin/bash
# Complete Configuration Backup - Push Branch and Create PR
# Usage: Run this script with GitHub authentication configured

set -e

TIMESTAMP=1770903175
BACKUP_BRANCH="backup/config-${TIMESTAMP}"
DATE_FORMATTED="2026-02-12"

echo "Completing configuration backup..."
echo "Branch: ${BACKUP_BRANCH}"
echo "Timestamp: ${TIMESTAMP} (${DATE_FORMATTED})"

# Check if branch exists locally
if ! git show-ref --verify --quiet "refs/heads/${BACKUP_BRANCH}"; then
    echo "ERROR: Backup branch ${BACKUP_BRANCH} does not exist locally"
    echo "The branch may need to be recreated. See BACKUP_MANIFEST_${TIMESTAMP}.md for details."
    exit 1
fi

# Push the backup branch
echo "Pushing backup branch to GitHub..."
git push origin "${BACKUP_BRANCH}"

# Create Pull Request
echo "Creating pull request..."
gh pr create \
    --head "${BACKUP_BRANCH}" \
    --title "Configuration Backup - ${DATE_FORMATTED}" \
    --body "Automated configuration backup created at Unix timestamp ${TIMESTAMP} (${DATE_FORMATTED} 13:32:55 UTC)

## What's Backed Up

This PR contains a comprehensive backup of all configuration files:

- **GitHub Workflows** (.github/workflows/) - All automation workflows
- **Operating System** (operating_system/) - Agent personality, cron jobs, triggers
- **Event Handler** (event_handler/) - Server, cron, triggers, Claude integration, tools
- **Pi Configuration** (.pi/) - System prompt, skills, extensions
- **Docker Setup** - Dockerfile, entrypoint.sh
- **Documentation** (docs/) - All system documentation
- **Root Config** - package.json, README.md, etc.

## Purpose

This backup preserves the current state of all configuration for easy recovery if needed. See BACKUP_MANIFEST_${TIMESTAMP}.md for full details and recovery instructions.

## Recovery

To restore specific files:
\`\`\`bash
git checkout ${BACKUP_BRANCH} -- path/to/file
\`\`\`

For full restore:
\`\`\`bash
git merge ${BACKUP_BRANCH}
\`\`\`" \
    --base main

echo "Backup complete!"
echo "Branch: ${BACKUP_BRANCH}"
echo "Pull request created successfully"
