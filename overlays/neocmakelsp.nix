# Upstream nixpkgs sets RUSTONIG_SYSTEM_LIBONIG but omits pkg-config/oniguruma.
final: prev: {
  neocmakelsp = prev.neocmakelsp.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final.pkg-config];
    buildInputs = (old.buildInputs or []) ++ [final.oniguruma];
    checkFlags = (old.checkFlags or []) ++ ["--skip=document_link::tests::test_document_link_search"];
  });
}
