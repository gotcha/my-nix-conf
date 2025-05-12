{ pkgs, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    vim
    starship
    nixfmt-rfc-style
    devenv
  ];

  # Auto upgrade nix package and the daemon service.
  nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [
    "root"
    "gotcha"
  ];
  nix.settings.access-tokens = [
    "github.com=REMOVED-TOKEN"
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew.enable = true;
  homebrew.brews = [ ];
  homebrew.casks = [
    "thunderbird"
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
    "libreoffice"
    "dropbox"
    "vlc"
    "ollama"
  ];

  system.defaults.CustomSystemPreferences = {
    "com.apple.universalaccess" =     {
        "com.apple.custommenu.apps" =         [
            "NSGlobalDomain"
            "org.mozilla.firefox"
            "com.apple.finder"
            "com.googlecode.iterm2"
            "net.whatsapp.WhatsApp"
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
    "net.whatsapp.WhatsApp" =     {
        NSUserKeyEquivalents =         {
            "Enter Full Screen" = "~^f";
            "Exit Full Screen" = "~^f";
        };
    };
    "com.googlecode.iterm2" =     {
        NSUserKeyEquivalents =         {
            "Toggle Full Screen" = "~^f";
        };
    };
  };
    system.activationScripts.postUserActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}


