{
  pkgs,
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
  imports = [
    ./modules
    ./modules/apps/openrct2.nix
  ];

  # Set my home directory
  home = {
    username = "kiran";
    homeDirectory = "/home/kiran";
  };

  # Sync to Work, Laptop, and NAS
  services.syncthing.settings = syncWith ["NAS" "Laptop" "Work"];

  # Kix-specific packages
  home.packages = with pkgs; [
    negpy
    protonup-qt
    via
  ];

  # NixOS State Version for Home
  home.stateVersion = "25.05";
}
