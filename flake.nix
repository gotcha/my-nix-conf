{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

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

    homebrew-humanlayer = {
      url = "github:humanlayer/homebrew-humanlayer";
      flake = false;
    };

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";


    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nix.follows = "nix-gotcha";
      inputs.nixpkgs.follows = "nixpkgs-devenv";
    };

    nixpkgs-devenv.url = "github:cachix/devenv-nixpkgs/d1c30452ebecfc55185ae6d1c983c09da0c274ff";

    nix-gotcha.url = "github:gotcha/nix/devenv-2.32";
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
      homebrew-humanlayer,
      nur,
      nix-rosetta-builder,
      devenv,
      nix-gotcha,
      nixpkgs-devenv,
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
	specialArgs = { inherit inputs; };
        modules = [
	  # An existing Linux builder is needed to initially bootstrap `nix-rosetta-builder`.
	  # If one isn't already available: comment out the `nix-rosetta-builder` module below,
	  # uncomment this `linux-builder` module, and run `darwin-rebuild switch`:
	  # { nix.linux-builder.enable = true; }
	  # Then: uncomment `nix-rosetta-builder`, remove `linux-builder`, and `darwin-rebuild switch`
	  # a second time. Subsequently, `nix-rosetta-builder` can rebuild itself.
	  # nix-rosetta-builder.darwinModules.default
	  # {
	  #   # see available options in module.nix's `options.nix-rosetta-builder`
	  #   nix-rosetta-builder.enable = true;
	  #   nix-rosetta-builder.onDemand = false;
	  # }
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.users.gotcha =
              { config, pkgs, ... }:
              {
                nixpkgs.overlays = [
                  inputs.nur.overlays.default
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
                "humanlayer/homebrew-humanlayer" = inputs.homebrew-humanlayer;
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
