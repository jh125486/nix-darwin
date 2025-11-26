{
  description = "Developer macOS system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-vscode-extensions,
    }:
    let
      user = "jacob.hochstetler";
      hostname = "CENG-M-139576";
      configuration =
        { pkgs, ... }:
        {
          nix.enable = false;
          environment.systemPackages = with pkgs; [
            # System packages
            awscli
            coreutils
            exiftool
            gh
            google-cloud-sdk
            goreleaser
            htop
            jq
            nmap
            scc
            vhs
            vim
            watch
            wget
            wireguard-tools
            yq

            # Languages
            buf
            cargo
            go
            hugo
            jupyter
            python3
            rustc
            tinygo
            zig

            # GUI Apps
            drawio
            hoppscotch
            inkscape
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

          system.primaryUser = user;

          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = true;
              upgrade = true;
              cleanup = "zap";
              extraFlags = [ "--force" ]; # Ensure forced updates
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
              "changie"
              "coreutils"
              "direnv"
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
              "mkvtoolnix"
              "ncdu"
              "ninja"
              "nixfmt"
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
              "yq"
              "yt-dlp"
              "yubico-piv-tool"
              "zig"
            ];
            casks = [
              "1password"
              "adobe-creative-cloud"
              "bartender"
              "chatgpt"
              "dbeaver-community"
              "discord"
              "displaylink"
              "docker-desktop"
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
              "proton-mail"
              "protonvpn"
              "qflipper"
              "rstudio"
              "shottr"
              "signal"
              "stats"
              "steam"
              "whatsapp"
              "yubico-authenticator"
              "yubico-yubikey-manager"
            ];
          };

          system.configurationRevision = self.rev or self.dirtyRev or null;

          system.defaults.dock.orientation = "right";

          system.defaults.finder.FXPreferredViewStyle = "Nlsv";

          system.defaults.finder.FXDefaultSearchScope = "SCcf";

          system.defaults.dock.persistent-apps = [
            "/Applications/Proton Mail.app"
            "/Applications/Microsoft Outlook.app"
            "/Applications/Microsoft Teams.app"
            "/Applications/Microsoft Edge.app"
            "/Users/${user}/Applications/Edge Apps.localized/ChatGPT.app"
            "/Users/${user}/Applications/Edge Apps.localized/Canvas.app"
            "/System/Applications/Reminders.app"
            "/System/Applications/Notes.app"
            "/System/Applications/Messages.app"
            "/Applications/Signal.app"
            "/Applications/Discord.app"
            "/Applications/WhatsApp.app"
            "/Users/jacob.hochstetler/Applications/IntelliJ IDEA Ultimate.app"
            "/Users/${user}/Applications/Home Manager Apps/Visual Studio Code.app"
            "/Users/${user}/Parallels/Windows 11.pvm/Windows 11.app"
            "/Applications/Ghostty.app"
            "/Applications/Docker.app"
            "/Users/${user}/Applications/Edge Apps.localized/Spotify.app"
          ];

          system.stateVersion = 6;
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config.allowUnfree = true;

          security.pam.services.sudo_local.touchIdAuth = true;
        };

      homeManagerConfig =
        { pkgs, ... }:
        {
          home.stateVersion = "25.05";
          programs.home-manager.enable = true;
          home.packages = with pkgs; [
            nixpkgs-fmt
            coreutils-full
          ];
          home.sessionVariables = {
            EDITOR = "vim";
          };
          home.sessionPath = [
            "$HOME/bin"
            "$HOME/go/bin"
          ];

          programs.zsh = {
            enable = true;
            shellAliases = {
              "update-nix" = "sudo darwin-rebuild switch --flake ~/.config/nix";
              "code" = "/Users/${user}/Applications/Home Manager Apps/Visual Studio Code.app/Contents/Resources/app/bin/code";
            };
          };

          programs.git = {
            enable = true;
            ignores = [
              ".DS_Store"
              ".idea"
              "*.iml"
            ];
            settings = {
              user = {
                name = "Jacob Hochstetler";
                email = "jacob.hochstetler@gmail.com";
                signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDJCefoRQh6F9GJ6H86GcXz+FHXhkfkK8J1Q5eY05qe";
              };
              gpg = {
                format = "ssh";
                ssh = {
                  program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
                };
              };
              init = {
                defaultBranch = "main";
              };
              commit = {
                gpgsign = "true";
              };
              push = {
                autoSetupRemote = true;
              };
            };
          };

          programs.vscode = {
            enable = true;
            mutableExtensionsDir = true;
            profiles.default.extensions = with pkgs.vscode-marketplace; [
              atommaterial.a-file-icon-vscode
              bbenoist.nix
              budparr.language-hugo-vscode
              eamodio.gitlens
              # github.copilot  # Install manually via VSCode UI due to version mismatch
              # github.copilot-chat
              golang.go
              jinliming2.vscode-go-template
              jnoortheen.nix-ide
              marclipovsky.string-manipulation
              ms-azuretools.vscode-containers
              ms-azuretools.vscode-docker
              ms-vscode-remote.remote-containers
              ms-vscode.live-server
              ms-vscode.makefile-tools
              parallelsdesktop.parallels-desktop
              patriciodiaz.go-struct-analyzer
              sebastianpanetta.golang-table-driven-tests
              sonarsource.sonarlint-vscode
              timweightman.go-test-codelens-enhanced
              xiaoxuxxxx.gogo-codelens
              zxh404.vscode-proto3
            ];
            profiles.default.userSettings = {
              "window.zoomLevel" = -0.5;
              "editor.formatOnSave" = true;
              "files.autoSave" = "onFocusChange";
              "workbench.colorTheme" = "Dark (Visual Studio)";
              "go.coverOnSave" = true;
              "go.lintTool" = "golangci-lint";
              "go.lintOnSave" = "package";
              "go.testArgs" = [
                "-race"
                "-cover"
                "-shuffle=on"
              ];
              "sonarlint.pathToNodeExecutable" = "";
              "sonarlint.connectedMode.project" = {
                "projectKey" = "jacob.hochstetler_nix-darwin_AYsZBJF5xT0Ysq0Tl9mR";
              };
              "[nix]" = {
                "editor.defaultFormatter" = "jnoortheen.nix-ide";
              };
              "git.ignoreLimitWarning" = true;
            };
          };

          # Make VSCode settings writable while keeping extensions mutable
          home.activation.makeVSCodeSettingsWritable = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
            SETTINGS_FILE="$VSCODE_CONFIG_DIR/settings.json"

            # If the settings file is a symlink, replace it with a copy
            if [ -L "$SETTINGS_FILE" ]; then
              TARGET=$(readlink -f "$SETTINGS_FILE")
              run rm $VERBOSE_ARG "$SETTINGS_FILE"
              run cp $VERBOSE_ARG "$TARGET" "$SETTINGS_FILE"
              run chmod $VERBOSE_ARG u+w "$SETTINGS_FILE"
            fi

            # Remove old immutable extensions symlink if it exists
            EXTENSIONS_DIR="$HOME/.vscode/extensions"
            if [ -L "$EXTENSIONS_DIR" ]; then
              run rm $VERBOSE_ARG "$EXTENSIONS_DIR"
              run mkdir -p "$EXTENSIONS_DIR"
            fi
          '';
        };

    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.backupFileExtension = "backup";

            home-manager.users.${user} = homeManagerConfig;
          }
        ];
      };
    };
}
