# agentaps — desktop agent workbench (github.com/cachix/agentaps), DMG-pinned,
# same pattern as sayit.nix. Upgrading: bump version + hash, re-switch; the
# activation below replaces /Applications/Agentaps.app (quit the app first).
# Release binaries are adhoc-signed and unnotarized, but the ditto copy from
# the nix store carries no quarantine xattr, so Gatekeeper does not block it.
{ config, lib, pkgs, ... }:
let
  appInstallPath = "/Applications/Agentaps.app";

  agentapsApp = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "agentaps";
    version = "0.5.2";
    src = pkgs.fetchurl {
      url = "https://github.com/cachix/agentaps/releases/download/v${finalAttrs.version}/Agentaps_${finalAttrs.version}_aarch64.dmg";
      hash = "sha256-IJUE4QrDiTWfSYpwr8FlwU6GLihode/2rSohQQd7sKo=";
    };
    # undmg cannot read APFS DMGs (libdmg-hfsplus is HFS+-only); 7zz >= 24.09
    # walks the APFS volume directly. -sns- skips NTFS-style provenance
    # sidecar files. The DMG holds one top-level folder: Agentaps/Agentaps.app.
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
      cp -R "Agentaps/Agentaps.app" $out/Applications/
      runHook postInstall
    '';
  });
in
{
  home.activation.agentapsApp = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    stamp="/Applications/.agentaps.nix-store-path"
    if [[ ! -d "${appInstallPath}" || "$(cat "$stamp" 2>/dev/null)" != "${agentapsApp}" ]]; then
      # ditto preserves the nix store's read-only modes (dirs are r-xr-xr-x);
      # rm -rf then dies "Permission denied" inside non-writable directories.
      # Grant owner write before removing, and keep the fresh copy owner-
      # writable so future activations can remove it the same way.
      if [[ -d "${appInstallPath}" ]]; then
        run chmod -R u+w "${appInstallPath}" || true
      fi
      run rm -rf "${appInstallPath}"
      run /usr/bin/ditto "${agentapsApp}/Applications/Agentaps.app" "${appInstallPath}"
      run chmod -R u+w "${appInstallPath}"
      run /usr/bin/env sh -c "printf %s '${agentapsApp}' > '$stamp'"
    fi
  '';
}
