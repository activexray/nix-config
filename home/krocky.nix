{
  pkgs,
  config,
  nixgl,
  lib,
  ...
}: let
  syncDevices = import ./modules/services/syncthing-devices.nix;
  # Share the ~/sync folder with the named devices.
  syncWith = names: {
    devices = lib.genAttrs names (name: {id = syncDevices.${name};});
    folders."apybf-p3tmn".devices = names;
  };
in {
  # Setup NixGL
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "nvidia";
    installScripts = ["nvidia"];
  };

  imports = [./modules];

  # Set my home directory
  home = {
    username = "kshila";
    homeDirectory = "/home/kshila";
  };

  # Setup bash to just launch fish
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # Rocky uses gnome, so switch the pinentry (and wrap with nixgl)
  services.gpg-agent.pinentry.package = config.lib.nixGL.wrap pkgs.pinentry-gnome3;

  # We have to handle the SSH_AUTH_SOCK manually
  programs.fish.interactiveShellInit = lib.mkAfter ''
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  # GNOME Keyring's own SSH-agent component autostarts at
  # X-GNOME-Autostart-Phase=PreDisplayServer -- before almost everything
  # else in the session -- and claims SSH_AUTH_SOCK for the whole
  # graphical session, ahead of gpg-agent's, which is why the above is
  # necessary for shells too. This only disables the ssh-agent piece;
  # secret storage (saved passwords, etc.) is a separate GNOME Keyring
  # component and keeps running.
  xdg.configFile."autostart/gnome-keyring-ssh.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  # Krocky-specific packages
  home.packages = [(config.lib.nixGL.wrap pkgs.looking-glass-client)];

  # Sync to Home, Laptop, and NAS
  services.syncthing.settings = syncWith ["NAS" "Home" "Laptop"];

  # Enable just work email on work machine
  accounts.email.accounts = {
    "me@kiranshila.com" = {
      primary = false;
      thunderbird.enable = false;
    };
    "kshila@caltech.edu" = {
      primary = true;
    };
  };

  # Emacs to nixgl-ed non-wayland
  programs.doom-emacs.emacs = config.lib.nixGL.wrap pkgs.emacs;

  # NixOS State Version for Home
  home.stateVersion = "25.05";
}
