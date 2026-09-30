# ~/.agents/skills managed as out-of-store symlinks into live checkouts.
# nix guarantees placement; git guarantees content.
#
# Roots:
#   ~/co/skills                — authored + vendored single skills (github.com/gotcha/skills).
#                                Add entries via the add-skill skill; keep the list sorted.
#   ~/co/poteto-mode-port      — the pstack port (github.com/gotcha/poteto-mode-port).
#                                Managed in that repo; add new pstack skills to the list here.
{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory;
  skillRoots = {
    "${homeDir}/co/skills" = [
      "add-skill"
      "grilling"
      "sats-dev-init"
    ];
    "${homeDir}/co/poteto-mode-port/skills" = [
      "architect"
      "arena"
      "automate-me"
      "blast-radius"
      "bro"
      "create-verification-skill"
      "figure-it-out"
      "how"
      "interrogate"
      "maintain-verification-skill"
      "make-bot-ui"
      "no-comments"
      "poteto-mode"
      "principle-boundary-discipline"
      "principle-build-the-lever"
      "principle-encode-lessons-in-structure"
      "principle-exhaust-the-design-space"
      "principle-experience-first"
      "principle-fix-root-causes"
      "principle-foundational-thinking"
      "principle-guard-the-context-window"
      "principle-laziness-protocol"
      "principle-make-operations-idempotent"
      "principle-migrate-callers-then-delete-legacy-apis"
      "principle-minimize-reader-load"
      "principle-model-the-domain"
      "principle-never-block-on-the-human"
      "principle-outcome-oriented-execution"
      "principle-prove-it-works"
      "principle-redesign-from-first-principles"
      "principle-separate-before-serializing-shared-state"
      "principle-sequence-verifiable-units"
      "principle-subtract-before-you-add"
      "principle-type-system-discipline"
      "recall"
      "reflect"
      "setup-pstack"
      "show-me-your-work"
      "swarm"
      "tdd"
      "teach"
      "technical-writing"
      "typescript-best-practices"
      "unslop"
      "why"
    ];
  };
  link = root: name: {
    name = ".agents/skills/${name}";
    value.source = config.lib.file.mkOutOfStoreSymlink "${root}/${name}";
  };
in
{
  home.file = builtins.listToAttrs (
    builtins.concatLists (
      lib.mapAttrsToList (root: builtins.map (link root)) skillRoots
    )
  );
}
