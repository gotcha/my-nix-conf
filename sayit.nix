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
      run rm -rf "${appInstallPath}"
      run /usr/bin/ditto "${sayitApp}/Applications/Say It.app" "${appInstallPath}"
      run /usr/bin/env sh -c "printf %s '${sayitApp}' > '$stamp'"
    fi
  '';
  targets.darwin.defaults."sh.sayit.mac".SUEnableAutomaticChecks = false;
}
