# AGENTS.md

- Run `just doctor` after Nix changes when practical.
- Do not commit secrets, auth files, sessions, or runtime state.
- Manage GUI apps with Homebrew casks in `modules/machines/darwin/_common/homebrew.nix`.
- Manage CLI tools with Nix/Home Manager under `modules/users/mkn/`.
- Keep comments short and useful.
