Update `entrypoint.sh` to add `git config push.autoSetupRemote true` right after the git credentials setup. This ensures that all future jobs can push to new branches without requiring explicit upstream configuration.

Specifically:
1. Find the line where git is configured (around `gh auth setup-git`)
2. Add a new line after it: `git config --global push.autoSetupRemote true`
3. Commit the change with message "thepopebot: enable auto-upstream git config"
4. Push to main

This is a one-line addition that improves reliability for all future jobs.