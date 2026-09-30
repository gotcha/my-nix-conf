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

    homebrew-zmx = {
      url = "github:neurosnap/homebrew-tap";
      flake = false;
    };

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";


    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv/v2.4.0";
      inputs.nixpkgs.follows = "nixpkgs-devenv";
    };

    # Pinned to the rev that devenv v2.3.1's own flake.lock uses, so the build
    # matches devenv.cachix.org and substitutes instead of compiling.
    # Do NOT switch to /rolling: its newer darwin stdenv exports
    # NIX_ENFORCE_PURITY=1, and devenv-proxy's openssl-sys links impurely
    # (probes /opt/homebrew), so the build dies with "ld: library not found -lssl".
    # When bumping the devenv tag, take the rev from that tag's flake.lock.
    # curl -s https://raw.githubusercontent.com/cachix/devenv/v2.4.0/flake.lock | jq -r '.nodes.nixpkgs.locked.rev'
    nixpkgs-devenv.url = "github:cachix/devenv-nixpkgs/256551e45f6303e142ab4a98be1bf243feb77dc0";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    maple-cask = {
      url = "path:/Users/gotcha/co/maple-cask";
      flake = false;
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    llm-agents.inputs.bun2nix.url = "git+https://github.com/nix-community/bun2nix";

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
      homebrew-zmx,
      nur,
      nix-rosetta-builder,
      devenv,
      nixpkgs-devenv,
      nix-index-database,
      maple-cask,
      llm-agents,
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
	    home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.gotcha =
              { config, pkgs, inputs, ... }:
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
		"neurosnap/hombrew-tap" = inputs.homebrew-zmx;
                "local/homebrew-cask" = inputs.maple-cask;
              };

              mutableTaps = false;
            };
          }
	  nix-index-database.darwinModules.nix-index
          { programs.nix-index-database.comma.enable = true; }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."gotcha-M2".pkgs;
    };
}
