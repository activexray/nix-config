{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.opencode = {
    enable = true;
    package = pkgs.llm-agents.opencode;
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    context = ./claude-contract.md;
    settings = {
      tui = "fullscreen";
      statusLine = {
        type = "command";
        command = "${pkgs.llm-agents.ccstatusline}/bin/ccstatusline";
        padding = 0;
      };
      attribution = {
        commit = "";
        pr = "";
        # commit/pr only blank the Co-Authored-By text; the Claude-Session
        # trailer on web and Remote Control sessions is its own toggle
        sessionUrl = false;
      };
    };
  };

  # ccstatusline rewrites its own settings.json on every run (schema
  # migration/normalization). A home-manager xdg.configFile symlink points
  # into the read-only nix store, so that write fails with EACCES and
  # ccstatusline falls back to showing "invalid config" in the statusline.
  # Seed a real, writable copy instead; leave it alone once it exists so
  # ccstatusline's own rewrites (and any in-app edits) stick.
  home.activation.ccstatuslineConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.config/ccstatusline/settings.json"
    if [ ! -e "$target" ] || [ -L "$target" ]; then
      run mkdir -p "$(dirname "$target")"
      run install -m 0644 ${./ccstatusline-config.json} "$target"
    fi
  '';
}
