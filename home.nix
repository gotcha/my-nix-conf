{
  inputs,
  config,
  pkgs,
  lib, 
  ...
}:
let 
  nhswitch = pkgs.writeShellApplication {
    name = "nhswitch";
    runtimeInputs = [ pkgs.nh ];
    text = ''
      nh darwin switch -H gotcha-M2;
      tmux set-environment -g PATH "$PATH";
      '';
  };

  reloadzsh = pkgs.writeShellApplication {
    name = "reloadzsh";
    text = ''
      unset __NIX_DARWIN_SET_ENVIRONMENT_DONE; unset __HM_SESS_VARS_SOURCED; exec zsh
      '';
  };

  # absolute path to a local zc.buildout checkout (impure but handy),
  # or a fetchFromGitHub once the branch lands upstream
  buildoutCheckout = /Users/gotcha/co/buildout-grammar;
  buildoutNvim = pkgs.stdenv.mkDerivation {
    pname = "nvim-treesitter-buildout";
    version = "unstable-2026-09-08";
    src = buildoutCheckout + /editors/nvim;
    parserSrc = buildoutCheckout + /tree-sitter-buildout/src;
    buildPhase = ''
      runHook preBuild
      mkdir -p parser
      cc -O2 -shared -fPIC -o parser/buildout.so \
        "$parserSrc/parser.c" -I "$parserSrc"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r ftdetect ftplugin queries parser $out/
      runHook postInstall
    '';
  };
in

{
  imports = [ ./skills.nix ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "gotcha";
  home.homeDirectory = pkgs.lib.mkDefault "/Users/gotcha";

  home.sessionVariables = {
    GHCR_TOKEN = "REMOVED-TOKEN";
    NH_DARWIN_FLAKE="${config.home.homeDirectory}/.config/nix-darwin";
  };


  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    secretspec
    fd
    just
    btop
    fh
    gh
    colima
    podman
    tig
    jujutsu
    lazyjj
    claude-code
    (writeShellScriptBin "docker" ''
      ${podman}/bin/podman "$@"
     '')
    bitcoind
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    nhswitch
    reloadzsh
    (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; goose-cli)
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/gotcha/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh.enable = true;
  programs.zsh.initContent = lib.mkOrder 1500 ''
      bindkey "^Xa" beginning-of-line
      eval "$(devenv hook zsh)"
  '';
  programs.zsh.autosuggestion.enable = true;
  programs.zsh.dotDir = "${config.xdg.configHome}/zsh";
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.history.save = 2000000;
  programs.zsh.history.size = 2000000;
  programs.zsh.historySubstringSearch.enable = true;
  programs.zsh.sessionVariables = {
    EDITOR = "nvim";
  };
  programs.zsh.plugins = [
    {
      name = "you-should-use";
      src = pkgs.fetchFromGitHub {
        owner = "MichaelAquilina";
        repo = "zsh-you-should-use";
        rev = "1f9cb008076d4f2011d5f814dfbcfbece94a99e0";
        sha256 = "sha256-lKs6DhG3x/oRA5AxnRT+odCZFenpS86wPnPqxLonV2E=";
      };
    }
    {
      name = "auto-notify";
      src = pkgs.fetchFromGitHub {
        owner = "MichaelAquilina";
        repo = "zsh-auto-notify";
        rev = "22b2c61ed18514b4002acc626d7f19aa7cb2e34c";
        sha256 = "sha256-x+6UPghRB64nxuhJcBaPQ1kPhsDx3HJv0TLJT5rjZpA=";
      };
    }
  ];

  programs.git.enable = true;
  programs.git.settings.alias = {
    co = "checkout";
    st = "status";
  };
  # programs.git.includes = [ { path = "~/.config/git/git-credential-oauth.inc"; } ];
  programs.git.settings.user.name = "Godefroid Chapelle";
  programs.git.settings.user.email = "gotcha@bubblenet.be";
  programs.git.settings = {
    pull = {
      rebase = true;
    };
    "credential \"https://redcat.communities.buzz.xyz\"" = {
      helper = "/Applications/Buzz.app/Contents/MacOS/git-credential-nostr";
      useHttpPath = true;
    };
  };

  programs.bat.enable = true;
  programs.bat.config = {
    theme = "Solarized (light)";
  };

  programs.jujutsu.enable = true;

  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  programs.neovim.vimAlias = true;
  programs.neovim.withPython3 = false;
  programs.neovim.withRuby = false;
  programs.neovim.plugins = with pkgs.vimPlugins; [
    { plugin = vim-fugitive; }
    vim-vinegar
    vimelette
    bufexplorer
    telescope-nvim
    nvim-treesitter
    nvim-treesitter-textobjects
    vim-surround
    vim-commentary
    gitsigns-nvim
    lualine-nvim
    vim-obsession
    nvim-web-devicons
    avante-nvim
    which-key-nvim
    { plugin = buildoutNvim; }
  ];
  programs.neovim.extraConfig = ''
    set autochdir
    set mouse=
    " for devicons
    set encoding=UTF-8
    let mapleader=","
    " fugitive
    nnoremap <leader>gs :G<cr>
    " bufexplorer
    nnoremap <leader>b :BufExplorer<cr>
    " for commentary
    autocmd FileType nix setlocal commentstring=#\ %s
    if exists("g:neovide")
      set guifont=Mononoki\ Nerd\ Font:h19
    endif
  '';
  programs.neovim.initLua = '''';

  programs.eza.enable = true;
  
  programs.zoxide.enable = true;

  programs.sesh.enable = true;
  programs.sesh.enableTmuxIntegration = true;
  programs.sesh.tmuxKey = "z";

  programs.fzf.enable = true;
  programs.fzf.historyWidget.command = "";
  programs.fzf.tmux.enableShellIntegration = true;

  programs.tmux = { 
    enable = true;
    baseIndex = 1;
    # tmux 3.7c
    package = pkgs.tmux.overrideAttrs (oldAttrs: {
      buildInputs = builtins.filter (p: p.pname or "" != "jemalloc") oldAttrs.buildInputs;
      configureFlags = (oldAttrs.configureFlags or []) ++ [ "--disable-jemalloc" ];
    });
    prefix = "C-a";
    extraConfig = ''
      bind-key C-a send-key C-a
      bind c new-window -c "#{pane_current_path}"
      bind r source-file ~/.config/tmux/tmux.conf\; display "Reloaded"
    '';
    plugins = with pkgs.tmuxPlugins; [
      sessionist
      { 
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-processes 'vim nvim'
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      { 
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-boot 'on'
          set -g @continuum-boot-options 'iterm,fullscreen'
          set -g @continuum-save-interval '5'
        '';
      }
    ];
  };

  programs.zellij.enable = true;
  programs.zellij.enableZshIntegration = false;
  programs.zellij.settings = {
    mouse_mode = false;
    pane_frames = false;
    keybinds = {
      tmux = {
        bind = {
          _args = [ "Ctrl a" ];
          Write = 2;
          SwitchToMode = "Normal";
        };
      };
      shared_except = {
        _args = [
          "tmux"
          "locked"
        ];
        bind = {
          _args = [ "Ctrl a" ];
          SwitchToMode = "Tmux";
        };
      };
    };
  };

  programs.mcfly.enable = false;
  programs.mcfly.enableZshIntegration = false;

  programs.atuin.enable = true;
  programs.atuin.enableZshIntegration = true;

  programs.ripgrep.enable = true;

  programs.git-credential-oauth.enable = true;

  programs.starship.enable = true;
  programs.starship.settings = {
    add_newline = false;
    format = pkgs.lib.concatStrings [ "$all$directory$character" ];
    scan_timeout = 10;
    character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[➜](bold red)";
    };
    directory = {
      truncation_length = 8;
      truncation_symbol = "…/";
      truncate_to_repo = false;
    };
  };

  xdg.enable = true;
  # xdg.configFile."git/git-credential-oauth.inc".text = ''
  #   [credential]
  #   helper = osxkeychain
  #   helper = cache --timeout 7200  # two hours
  #   helper = oauth
  # '';
}

# TODO
# Install mononoki font
# download mononoki font
# setup mononoki font in iTerm
