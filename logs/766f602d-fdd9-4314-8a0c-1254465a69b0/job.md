Update `entrypoint.sh` to fix Git upstream configuration:

1. Move `git config --global push.autoSetupRemote true` to EARLIER in the script - right after the initial git setup, before the repository is cloned. This ensures the config is set globally before any push operations.

2. Also add `--set-upstream origin` flag to all `git push` commands in the script and in any backup/job execution scripts to explicitly set upstream branches.

3. Test that the configuration works by ensuring future pushes don't require manual upstream configuration.

4. Commit with message "thepopebot: fix git upstream config timing"

5. Push to main

This ensures the auto-upstream feature is properly initialized before any Git operations occur.