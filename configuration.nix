{ pkgs, inputs, ... }:
  let
    pkgs-goose = "obsolete";
  in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    vim
    starship
    nixfmt
    inputs.devenv.packages.${pkgs.stdenv.system}.devenv
    nh
  ];

  environment.variables = {
  };

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;
  # In flake.nix, add cachix's cache
nix.settings.substituters = [ "https://devenv.cachix.org" ];
nix.settings.trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];

  ids.gids.nixbld = 350;

  # for rosetta-builder
  nix.settings.builders-use-substitutes = pkgs.lib.mkForce false;
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [
    "root"
    "gotcha"
  ];
  # access-tokens live outside this repo (chmod 600, not committed):
  nix.extraOptions = "include /Users/gotcha/.config/nix/nix-private.conf";

  launchd.user.agents.set-ulimit = {
    script = "ulimit -n 65536";
    serviceConfig.RunAtLoad = true;
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  system.primaryUser = "gotcha";

  # Hidden files in Open/Save dialogs (and every app's file panels)
  system.defaults.NSGlobalDomain.AppleShowAllFiles = true;

  # Hidden files (dotfiles) in Finder itself
  system.defaults.finder.AppleShowAllFiles = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";


  homebrew.enable = true;
  homebrew.caskArgs.no_quarantine = false;
  homebrew.brews = [ ];
  homebrew.taps = [ 
  ];
  homebrew.onActivation.autoUpdate = true;
  homebrew.casks = [
    "google-chrome"
    "thunderbird"
    "firefox"
    "signal"
    "musescore"
    "whatsapp"
    "telegram"
    "grandperspective"
    "raycast"
    "istat-menus"
    "espanso"
    "discord"
    "orbstack"
    {
      name = "libreoffice";
      greedy = true;
    }
    "dropbox"
    "vlc"
    "utm"  # virtual machines
    "beamer"
    "obsidian"
#    "maple-ai"
#    "ollama"
  ];

  system.defaults.CustomSystemPreferences = {
    "com.apple.universalaccess" =     {
        "com.apple.custommenu.apps" =         [
            "NSGlobalDomain"
            "org.mozilla.firefox"
            "com.apple.finder"
            "com.googlecode.iterm2"
            # "net.whatsapp.WhatsApp"
        ];
    };
  };
  system.defaults.CustomUserPreferences = {
    "com.apple.finder" =     {
        NSUserKeyEquivalents =         {
            "Enter Full Screen" = "~^f";
            "Exit Full Screen" = "~^f";
        };
    };
    "org.mozilla.firefox" =     {
        NSUserKeyEquivalents =         {
            "Enter Full Screen" = "~^f";
            "Exit Full Screen" = "~^f";
        };
    };
    # "net.whatsapp.WhatsApp" =     {
    #     NSUserKeyEquivalents =         {
    #         "Enter Full Screen" = "~^f";
    #         "Exit Full Screen" = "~^f";
    #     };
    # };
    "com.googlecode.iterm2" =     {
        NSUserKeyEquivalents =         {
            "Toggle Full Screen" = "~^f";
        };
    };
  };
    # system.activationScripts.postUserActivation.text = ''
    # # Following line should allow us to avoid a logout/login cycle
    # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  # '';
}


