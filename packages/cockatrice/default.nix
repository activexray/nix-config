{
  lib,
  stdenv,
  qt5,
  fetchFromGitHub,
  cmake,
  protobuf_21,
}: let
  protobuf = protobuf_21;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "cockatrice";
    version = "2026-06-26-Release-3.0.2";

    src = fetchFromGitHub {
      owner = "Cockatrice";
      repo = "Cockatrice";
      rev = finalAttrs.version;
      sha256 = "sha256-qn8pnC04uN994qLK4oXc3IiTpPMT3/gqHHBaEDkjsr4=";
    };

    patches = [ ./missing-qset-header.patch ];

    nativeBuildInputs = [
      cmake
      qt5.wrapQtAppsHook
    ];

    buildInputs = [
      qt5.qtbase
      qt5.qtmultimedia
      protobuf
      qt5.qttools
      qt5.qtwebsockets
    ];

    meta = {
      homepage = "https://github.com/Cockatrice/Cockatrice";
      description = "Cross-platform virtual tabletop for multiplayer card games";
      license = lib.licenses.gpl2Plus;
      maintainers = with lib.maintainers; [evanjs];
      platforms = with lib.platforms; linux;
    };
  })
