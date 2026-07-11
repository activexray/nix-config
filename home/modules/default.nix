# Common home-manager settings
{
  config,
  pkgs,
  ...
}: {
  # Password store
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (ext: with ext; [pass-otp]);
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/sync/.password-store";
    };
  };

  # Enable fontconfig
  fonts.fontconfig.enable = true;

  # Enable home-manager, the program
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Enable nix-index
  programs.nix-index.enable = true;

  # Enable Direnv using nix-direnv (faster than use_flake)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Enable atuin
  # On new deployments, run `atuin login -u kiranshila`
  # Then run atuin import auto; atuin sync;
  programs.atuin = {
    enable = true;
    settings = {
      sync_frequency = "5m";
    };
  };

  # Enable the local-component to browserpass
  # Extension is force-enabled via Extensions.Locked in firefox/policies.nix
  programs.browserpass = {
    enable = true;
    browsers = ["firefox"];
  };

  # cat replacement
  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      # batgrep # currently broken
      batwatch
    ];
  };

  # ls replacement
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  # Catppuccin Theme
  # This will configure the following programs (if managed with home-manager)
  # - atuin
  # - bat
  # - eza
  # - firefox
  # - fish
  # - helix
  # - kitty
  # - starship
  # - thunderbird
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "macchiato";
    thunderbird.profile = "default";
    firefox.enable = false;
  };

  # Don't build the home-manager options manual (unused). Its manpage
  # generation runs nixosOptionsDoc, whose intermediate options.json
  # derivation embeds the nixpkgs source path without context and warns.
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };

  # Minecraft
  home.packages = with pkgs; [
    (prismlauncher.override {
      additionalPrograms = [ffmpeg]; # Some mods need it
    })

    # Fonts
    julia-mono
    iosevka-bin
    (iosevka-bin.override {
      variant = "Aile";
    })
    (iosevka-bin.override {
      variant = "Slab";
    })
    (iosevka-bin.override {
      variant = "SGr-IosevkaTermSS09";
    })
    nerd-fonts.fira-code
  ];

  # Font Config
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["DejaVu Sans"];
    serif = ["DejaVu Serif"];
    monospace = ["DejaVu Sans Mono"];
  };

  # Bring in everything else that might need more configuration
  imports = [
    ./email.nix
    ./apps/emacs
    ./apps/discord.nix
    ./apps/firefox/firefox.nix
    ./apps/gui.nix
    ./apps/kicad.nix
    ./apps/kitty.nix
    ./apps/openscad.nix
    ./tools/cli.nix
    ./tools/fish.nix
    ./tools/git.nix
    ./tools/gpg.nix
    ./tools/ssh.nix
    ./tools/slop.nix
    ./services/calendar.nix
    ./services/syncthing.nix
  ];
}
