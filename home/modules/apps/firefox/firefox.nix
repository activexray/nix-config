{
  lib,
  config,
  pkgs,
  ...
}: let
  # NixGL wrap
  package = config.lib.nixGL.wrap pkgs.firefox;
  profile = "default";
  legacyPath = "${config.home.homeDirectory}/.mozilla/firefox";
in {
  warnings = lib.mkIf (builtins.pathExists legacyPath) [
    "Firefox: legacy profile directory '${legacyPath}' still exists. Move it to '${config.xdg.configHome}/mozilla/firefox' and remove the old directory."
  ];
  home.sessionVariables = {
    # Must be an executable, not the package dir; "firefox" resolves to the
    # final programs.firefox wrapper on PATH.
    DEFAULT_BROWSER = "firefox";
    BROWSER = "firefox";
  };
  programs.firefox = {
    inherit package;
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    policies = import ./policies.nix;
    profiles.${profile} = import ./profile.nix {inherit lib pkgs config;};
  };
}
