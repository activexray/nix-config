# Declarative default applications (~/.config/mimeapps.list).
# Unmanaged, this file drifted to stale/foreign handlers (removed
# vesktop.desktop, Slack for text/html). GUI "set default" dialogs
# can't write it while managed; change defaults here instead.
{
  lib,
  config,
  ...
}: let
  assoc = app: types: lib.genAttrs types (_: [app]);
in {
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      assoc "firefox.desktop" [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ]
      // assoc "thunderbird.desktop" [
        "x-scheme-handler/mailto"
        "x-scheme-handler/mid"
        "message/rfc822"
        "text/calendar"
        "x-scheme-handler/webcal"
        "x-scheme-handler/webcals"
      ]
      // assoc (
        if config.targets.genericLinux.enable
        then "zoom-flatpak-handler.desktop" # Flatpak, see apps/gui.nix
        else "Zoom.desktop"
      ) [
        "x-scheme-handler/zoommtg"
        "x-scheme-handler/zoomus"
        "x-scheme-handler/zoomphonecall"
      ]
      // {
        "x-scheme-handler/slack" = ["slack.desktop"];
        "x-scheme-handler/discord" = ["discord.desktop"];
        "x-scheme-handler/sgnl" = ["signal.desktop"];
        # Written by Claude Code itself; kept so login deep links survive
        "x-scheme-handler/claude-cli" = ["claude-code-url-handler.desktop"];
      };
  };
  # Replace the existing hand/app-written file instead of failing activation
  xdg.configFile."mimeapps.list".force = true;
}
