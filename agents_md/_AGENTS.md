# AGENTS.md

This file provides guidance for OpenCode.

## Rules

- Print the names of the skills to be loaded on the screen before implementing a specific task. Highlight the skill name(s) using bright color formatting.
- Write the code review result to a report file. The timestamp should be part of the file name to avoid overwriting.
- If a required tool is not installed, ask the user for their sudo password and then run: `sudo -S apt update && sudo -S apt install <tool>`
