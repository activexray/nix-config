{
  config,
  pkgs,
  stablePkgs,
  ...
}: let
  bosl2 = pkgs.fetchFromGitHub {
    owner = "BelfrySCAD";
    repo = "BOSL2";
    rev = "afe82db884ee4409aa76ecfcfbbf54d446964af1";
    sha256 = "sha256-J0dkeHYlh2UFiAwubVvV8gx03RJ1BPBfqkn6Y4qUEVI=";
  };
in {
  # OpenSCAD, the binary
  home.packages = [(config.lib.nixGL.wrap stablePkgs.openscad-unstable)];

  # Create the library directory and symlink BOSL2
  home.file.".local/share/OpenSCAD/libraries/BOSL2".source = bosl2;
}
