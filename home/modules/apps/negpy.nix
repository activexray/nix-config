{
  config,
  pkgs,
  inputs,
  ...
}: let
  # numpy's MADV_HUGEPAGE on large arrays stalls in direct compaction when memory is fragmented.
  negpy = inputs.negpy.packages.${pkgs.system}.default.overrideAttrs (old: {
    postFixup =
      (old.postFixup or "")
      + ''
        wrapProgram $out/bin/negpy --set-default NUMPY_MADVISE_HUGEPAGE 0
      '';
  });
in {
  home.packages = [
    (config.lib.nixGL.wrap negpy)
  ];
}
