# Machine-wide agent rules

Canonical location: `~/.config/nix-darwin/AGENTS.md` in the nix-darwin config repo. home-manager links this file into agents' config dirs (e.g. `~/.config/goose/AGENTS.md`). **Edit only the canonical copy; never edit linked copies.**

## Reporting
- When asked to write or modify code, report nothing beyond a summary description of the files touched.
- Only report about the app being worked on when explicitly requested; do not generate such reports unprompted.
- pstack model roles are configured in `~/.config/goose/pstack-models.md`. Read it before any delegate fan-out and honor one delegate per configured entry for panel roles.

## Tooling: nix only, never Homebrew
- Never use Homebrew to install or manage software. Use nix, declaratively: change packages by editing `~/.config/nix-darwin` (user packages in `home.nix`).
- If Homebrew ever seems forced, stop and ask the user first.

## Configuration changes live in nix
- Express every configuration change in the nix config (`~/.config/nix-darwin`) when possible.
- When a change cannot be expressed in nix (e.g. runtime state the app rewrites itself, like goose's `~/.config/goose/memory/`), explain why, offer concrete alternatives, and implement only after the user chooses.

## Code exploration and edits: ast-grep first
- Prefer the ast-grep MCP tools (`find_code`, `find_code_by_rule`, `dump_syntax_tree`) over text search whenever the target is code structure.
- Prefer `ast-grep run --rewrite` codemods for structural edits and rewrites; use plain edit/write tools for fine-grained changes.

## Git worktrees for real work
- For any non-trivial change in a git repo — always when multiple projects run in parallel — work in a worktree: `git worktree add .worktrees/<task> -b <task-branch>` and operate there. Ensure `.worktrees/` is ignored (add it to the repo's `.git/info/exclude` if missing).
- Always state the worktree location when handing back the work.
- This rule applies to `~/.config/nix-darwin` itself. That repo must stay clean: uncommitted drift is a defect — complain about it prominently, never normalize it.
