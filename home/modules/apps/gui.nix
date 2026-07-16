# nixGL-wrapped GUI applications and non-wrapped GUI apps
{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs;
    map config.lib.nixGL.wrap [
      onlyoffice-desktopeditors
      slack
      obsidian
      qucs-s
      cockatrice
      remmina
      prusa-slicer
      veracrypt
      qtpass
      signal-desktop
      zoom-us
      ghidra
    ];
}
