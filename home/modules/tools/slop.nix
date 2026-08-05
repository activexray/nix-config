{
  pkgs,
  config,
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
    };
  };

  xdg.configFile."ccstatusline/settings.json".source = ./ccstatusline-config.json;
}
