{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nix-homebrew.inputs.nix-darwin.follows = "nix-darwin";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    nixpkgs-firefox-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-bundle,
      nur,
      nixpkgs-firefox-darwin,
    }:
    let
      system = "aarch64-darwin";
      configuration = ./configuration.nix;
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#gotcha-M2
      darwinConfigurations."gotcha-M2" = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
                nixpkgs.overlays = [
                  inputs.nur.overlays.default
                  inputs.nixpkgs-firefox-darwin.overlay
                ];
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.users.gotcha =
              { config, pkgs, ... }:
              {
                nixpkgs.overlays = [
                  inputs.nur.overlays.default
                  inputs.nixpkgs-firefox-darwin.overlay
                ];
                nixpkgs.config.allowUnfree = true;
                imports = [ ./home.nix ];
              };
          }
          { users.users.gotcha.home = "/Users/gotcha"; }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "gotcha";

              taps = {
                "homebrew/homebrew-bundle" = homebrew-bundle;
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };

              mutableTaps = false;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."gotcha-M2".pkgs;
    };
}
