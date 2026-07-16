{
  pkgs,
  config,
  ...
}: {
  programs.mcp = {
    enable = true;
    servers = {
      ghidra-bridge = {
        command = "${pkgs.uv}/bin/uv";
        args = ["run" "--directory" "${config.home.homeDirectory}/src/ghidra-mcp" "bridge-mcp-ghidra"];
      };
    };
  };

  programs.opencode = {
    enable = true;
    package = pkgs.llm-agents.opencode;
    enableMcpIntegration = true;
  };
}
