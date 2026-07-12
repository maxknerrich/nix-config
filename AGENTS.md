# AGENTS.md

- Run `just doctor` after Nix changes when practical.
- Do not commit secrets, auth files, sessions, or runtime state.
- Manage `fawkes` GUI apps in `modules/machines/darwin/fawkes/apps.nix`.
- Manage shared CLI tools in `modules/users/mkn/terminal.nix`.
- Keep comments short and useful.
