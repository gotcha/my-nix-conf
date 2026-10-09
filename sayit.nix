# sayit — menu-bar neural TTS (github.com/callebtc/sayit), DMG-pinned.
# Human onboarding (cannot be declarative): launch Say It once, download a
# model in-app. The launchd agent is SMAppService-registered by the app itself
# (Config/sh.sayit.mac.agent.plist, BundleProgram) — do NOT add one here.
{ config, lib, pkgs, ... }:
let
  appInstallPath = "/Applications/Say It.app";
  cliPath = "${appInstallPath}/Contents/Helpers/SayItCLI.app/Contents/MacOS/sayit";

  sayitApp = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "sayit";
    version = "0.1.9";
    src = pkgs.fetchurl {
      url = "https://github.com/callebtc/sayit/releases/download/v${finalAttrs.version}/SayIt.dmg";
      hash = "sha256-juZkZHtd04O3JWMzwsui2iHkvMMXmVbJ3egI+WHV9RU=";
    };
    # undmg cannot read this release: SayIt.dmg is a UDIF/GPT image holding an
    # APFS partition, and libdmg-hfsplus only supports HFS+. 7-Zip (>=24.09)
    # walks into the APFS volume directly. -sns- skips the NTFS-style
    # "name:com.apple.provenance" sidecar files it would otherwise create.
    nativeBuildInputs = [ pkgs._7zz ];
    unpackPhase = ''
      runHook preUnpack
      7zz x -y -sns- "$src"
      runHook postUnpack
    '';
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -R "Say It.app" $out/Applications/
      mkdir -p $out/skill
      cp "$(find "Say It.app" -path '*SayItCore.framework*' -name SKILL.md | head -n1)" $out/skill/SKILL.md
      # Owner rule: voice is never the only channel. Written text comes FIRST:
      # post before you speak, unless the utterance is the terse spoken capsule
      # of a longer written message — then post that message first, speak after.
      cat >> $out/skill/SKILL.md <<'MD'

## Non-negotiable: written first, then spoken

Voice is never the only place an utterance lives, and order matters. Post
the written text FIRST, then launch the `sayit` call — every time. The
listener must never hear words that are not already on screen.

When the utterance is the terse spoken capsule of a longer written message:
post the full written message first, then speak the capsule. Do not post a
duplicate line for the capsule — the written message already carries it.
Everything else (progress updates, status changes, decisions, errors) gets
its own short written line, posted before it is spoken.

Speech is ephemeral and easy to miss; the written channel is the durable
record the listener can scroll back to. Written-then-spoken is the default,
not an extra step.
MD
      runHook postInstall
    '';
  });

  sayitCli = pkgs.writeShellApplication {
    name = "sayit";
    text = ''
      if [[ ! -x "${cliPath}" ]]; then
        echo "Say It.app is not installed at ${appInstallPath} yet." >&2
        echo "Run a darwin switch, then launch Say It once and download a model." >&2
        exit 1
      fi
      exec ${lib.escapeShellArg cliPath} "$@"
    '';
  };
in
{
  home.packages = [ sayitCli ];
  home.file.".agents/skills/sayit".source = "${sayitApp}/skill";
  home.activation.sayitApp = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    stamp="/Applications/.sayit.nix-store-path"
    if [[ ! -d "${appInstallPath}" || "$(cat "$stamp" 2>/dev/null)" != "${sayitApp}" ]]; then
      # ditto preserves the nix store's read-only modes (dirs are r-xr-xr-x);
      # rm -rf then dies "Permission denied" inside non-writable directories.
      # Grant owner write before removing, and keep the fresh copy owner-
      # writable so future activations can remove it the same way.
      if [[ -d "${appInstallPath}" ]]; then
        run chmod -R u+w "${appInstallPath}" || true
      fi
      run rm -rf "${appInstallPath}"
      run /usr/bin/ditto "${sayitApp}/Applications/Say It.app" "${appInstallPath}"
      run chmod -R u+w "${appInstallPath}"
      run /usr/bin/env sh -c "printf %s '${sayitApp}' > '$stamp'"
    fi
  '';
  targets.darwin.defaults."sh.sayit.mac".SUEnableAutomaticChecks = false;
}
