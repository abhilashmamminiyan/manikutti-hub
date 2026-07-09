# Workspace Customization Rules

<RULE[git_push]>
Before making any git push, you MUST ALWAYS run `git pull` (or `git fetch` and merge) to ensure your local branch is fully up-to-date with the remote branch. If there are merge conflicts, resolve them carefully before pushing. Do this every single time you push changes to a branch, as other automations or users might have pushed new commits.
</RULE[git_push]>
