---description: Git commit with auto-generated message based on changes---

Generate a concise and descriptive git commit message for the current changes.

First, review what has changed:
!`git status`

Then look at the actual diff to understand the nature of changes:
!`git diff --cached --stat 2>/dev/null || git diff --stat`

!`git diff --cached 2>/dev/null || git diff`

Based on the changes above, generate a git commit message following these conventions:
- Use present tense (e.g., "Add feature" not "Added feature")
- Keep it under 50 characters for the first line
- Use type prefixes when applicable: feat:, fix:, docs:, style:, refactor:, test:, chore:
- Focus on WHAT and WHY, not HOW

Then execute: git commit -m "<your generated message>"
