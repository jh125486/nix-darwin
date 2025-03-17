{
  description = "Developer macOS system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    inputs@{ self
    , nix-darwin
    , nixpkgs
    , home-manager
    , mac-app-util
    , nix-vscode-extensions
    }:
    let
      user = "jacob.hochstetler";
      hostname = "CENG-M-139576";
      configuration = { pkgs, ... }: {
        nix.enable = false;
        environment.systemPackages = with pkgs; [
          # System packages
          coreutils
          awscli
          google-cloud-sdk
          exiftool
          gh
          vim
          stats
          jq
          yq
          htop
          nmap
          vhs
          watch
          wget
          goreleaser
          scc
          wireguard-tools

          # Languages
          go
          golangci-lint
          buf
          rustc
          cargo
          zig
          python3
          jupyter
          hugo
          tinygo

          # GUI Apps
          dbeaver-bin
          docker
          drawio
          hoppscotch
          inkscape
          spotify
          wireshark
          yubico-piv-tool
          zed-editor
        ];

        # Declare the user that will be running `nix-darwin`
        users.users.${user} = {
          name = user;
          home = "/Users/${user}";
          packages = with pkgs; [ ];
        };

        homebrew = {
          enable = true;
          onActivation = {
            autoUpdate = true;
            upgrade = true;
            cleanup = "zap";
            extraFlags = [ "--force" ];  # Ensure forced updates
          };
          taps = [ 
            "buo/cask-upgrade"
            "goreleaser/tap"
          ];
          brews = [
            "agg"
            "arm-none-eabi-gcc"
            "automake"
            "avrdude"
            "awscli"
            "bazelisk"
            "buf"
            "coreutils"
            "exiftool"
            "gh"
            "goplus"
            "goreleaser"
            "gradle"
            "htop"
            "httpie"
            "john-jumbo"
            "jq"
            "jupyterlab"
            "kotlin"
            "maven"
            "changie"
            "mkvtoolnix"
            "ncdu"
            "ninja"
            "nmap"
            "open-ocd"
            "openapi-generator"
            "podman"
            "poppler"
            "qemu"
            "redis"
            "scc"
            "sl"
            "tmux"
            "tree"
            "vhs"
            "watch"
            "wget"
            "youtube-dl"
            "yt-dlp"
            "yq"
            "yubico-piv-tool"
            "zig"
          ];
          casks = [
            "1password"
            "adobe-creative-cloud"
            "bartender"
            "chatgpt"
            "db-browser-for-sqlite"
            "discord"
	          "displaylink"
            "docker"
            "ghostty"
            "github"
            "google-drive"
            "iterm2"
            "jetbrains-toolbox"
            "keepingyouawake"
            "logi-options+"
            "logitech-presentation"
            "microsoft-auto-update"
            "microsoft-edge"
            "openinterminal-lite"
            "parallels"
            "qflipper"
            "rstudio"
            "shottr"
            "signal"
            "whatsapp"
            "vscodium"
            "yubico-authenticator"
            "yubico-yubikey-manager"
          ];
        };

        nix.settings.experimental-features = "nix-command flakes";
        system.configurationRevision = self.rev or self.dirtyRev or null;

        system.defaults.dock.orientation = "right";
        
        system.defaults.finder.FXPreferredViewStyle = "Nlsv";
        
        system.defaults.finder.FXDefaultSearchScope = "SCcf";

        system.defaults.dock.persistent-apps = [
          "/Applications/Microsoft Outlook.app"
          "/Applications/Microsoft Teams.app"
          "/Applications/Microsoft Edge.app"
          "/Users/${user}/Applications/Edge Apps.localized/ChatGPT.app"
          "/Users/${user}/Applications/Canvas.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Notes.app"
          "/System/Applications/Messages.app"
          "/Applications/Signal.app"
          "/Applications/Discord.app"
          "/Applications/WhatsApp.app"
          "/Users/jacob.hochstetler/Applications/IntelliJ IDEA Ultimate.app"
          "/Applications/VSCodium.app"
          "/Users/${user}/Parallels/Windows 11.pvm/Windows 11.app"
          "/Applications/iTerm.app"
          "/Applications/Docker.app"
        ];

        system.stateVersion = 5;
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;

        security.pam.enableSudoTouchIdAuth = true;
      };

      homeManagerConfig = { pkgs, ... }: {
        home.stateVersion = "25.05";
        programs.home-manager.enable = true;
        home.packages = with pkgs; [ nixpkgs-fmt coreutils-full ];
        home.sessionVariables = { EDITOR = "vim"; };
        home.sessionPath = [ 
          "$HOME/bin"
          "$HOME/go/bin"
        ];
        # home.file.".vimrc".source = ./vim_configuration;

        programs.zsh = {
          enable = true;
          shellAliases = { 
            "update-nix" = "sudo -i nix upgrade-nix && sudo determinate-nixd upgrade && darwin-rebuild switch --flake ~/.config/nix"; 
            "code" = "codium"; 
          };
        };

        programs.git = {
          enable = true;
          userName = "Jacob Hochstetler";
          userEmail = "jacob.hochstetler@gmail.com";
          ignores = [ ".DS_Store" ];
          extraConfig = {
            core.excludesFile = "~/.gitignore";
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
          };
        };

        # This does a "trampoline" icon in the Dock :/
        # programs.vscode = {
        #   enable = true;
        #   # package = pkgs.vscodium;
        #   userSettings = {
        #     "editor.formatOnSave" = true;
        #     "files.autoSave" = "onFocusChange";
        #     "workbench.colorTheme" = "Dark (Visual Studio)";
        #   };
        #   extensions = with pkgs.vscode-extensions; [
        #     jnoortheen.nix-ide
        #   ];
        # };
      };

    in
    {
      darwinConfigurations.CENG-M-139576 = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;

            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];

            home-manager.users.${user} = homeManagerConfig;
          }
        ];
      };
    };
}
