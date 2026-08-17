{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    (config.lib.nixGL.wrap inputs.negpy.packages.${pkgs.system}.default)
  ];
}
