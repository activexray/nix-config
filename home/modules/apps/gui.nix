# nixGL-wrapped GUI applications and non-wrapped GUI apps
{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs;
    map config.lib.nixGL.wrap ([
        onlyoffice-desktopeditors
        slack
        obsidian
        qucs-s
        cockatrice
        remmina
        prusa-slicer
        veracrypt
        signal-desktop
        ghidra
      ]
      # nixpkgs zoom-us segfaults on non-NixOS ("Could not initialize GLX"
      # even under nixGL); krocky uses the Flatpak (us.zoom.Zoom) instead.
      ++ lib.optional (!config.targets.genericLinux.enable) zoom-us);

  # Zoom link handler for the Flatpak on non-NixOS. Firefox (nixpkgs + nixGL)
  # exports LD_LIBRARY_PATH with Nix libs; inherited by /usr/bin/flatpak it
  # fails to load (GLIBC_2.38 not found) and zoommtg:// links do nothing.
  xdg.desktopEntries = lib.mkIf config.targets.genericLinux.enable {
    zoom-flatpak-handler = {
      name = "Zoom (link handler)";
      exec = "/usr/bin/env -u LD_LIBRARY_PATH /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=zoom --file-forwarding us.zoom.Zoom @@u %U @@";
      noDisplay = true;
      mimeType = [
        "x-scheme-handler/zoommtg"
        "x-scheme-handler/zoomus"
        "x-scheme-handler/zoomphonecall"
      ];
    };
  };
}
