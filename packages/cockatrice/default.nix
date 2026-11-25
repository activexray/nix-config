{
  lib,
  stdenv,
  qt6,
  fetchFromGitHub,
  cmake,
  protobuf_21,
}: let
  protobuf = protobuf_21;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "cockatrice";
    version = "2026-10-10-Release-3.1.1";

    src = fetchFromGitHub {
      owner = "Cockatrice";
      repo = "Cockatrice";
      rev = finalAttrs.version;
      sha256 = "sha256-Qr5f21SmGXqRxKsT/K47JBBz3X6skr9aNwTXITJA/X0=";
    };

    nativeBuildInputs = [
      cmake
      qt6.wrapQtAppsHook
    ];

    buildInputs = [
      qt6.qtbase
      qt6.qtmultimedia
      qt6.qttools
      qt6.qtwebsockets
      protobuf
    ];

    meta = {
      homepage = "https://github.com/Cockatrice/Cockatrice";
      description = "Cross-platform virtual tabletop for multiplayer card games";
      license = lib.licenses.gpl2Plus;
      maintainers = with lib.maintainers; [evanjs];
      platforms = with lib.platforms; linux;
    };
  })
