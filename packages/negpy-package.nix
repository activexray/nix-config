{
  lib,
  stdenv,
  python3Packages,
  fetchFromGitHub,
  qt6,
  vulkan-loader,
  libGL,
}:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "negpy";
  version = "0.36.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "marcinz606";
    repo = "NegPy";
    tag = finalAttrs.version;
    hash = "sha256-ku6Hj0aNlTBOuNjUZqdghMCKMHPxzmkqDKo7B4Pe/Cw=";
  };

  pythonRelaxDeps = [
    "imagecodecs"
    "imageio"
    "numba"
    "numpy"
    "opencv-python-headless"
    "pillow"
    "qtawesome"
    "tifffile"
    "wgpu"
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'setuptools~=80.10.2' 'setuptools' \
      --replace-fail 'packages = ["negpy"]' 'include = ["negpy*"]'
    substituteInPlace pyproject.toml \
      --replace-fail '[tool.setuptools]' '[tool.setuptools.packages.find]'
  '';

  nativeBuildInputs = [qt6.wrapQtAppsHook];

  buildInputs =
    [
      qt6.qtbase
    ]
    ++ lib.optionals stdenv.isLinux [
      qt6.qtwayland
    ];

  build-system = [python3Packages.setuptools];

  dependencies = with python3Packages; [
    imagecodecs
    imageio
    jinja2
    numba
    numpy
    opencv-python-headless
    piexif
    pillow
    pyqt6
    pyqt6-charts
    pyserial
    qtawesome
    rawpy
    tifffile
    wgpu-py
  ];

  pythonImportsCheck = ["negpy"];

  dontWrapQtApps = true;
  preFixup = ''
    makeWrapperArgs+=(
      ''${qtWrapperArgs[@]}
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [vulkan-loader libGL]}
    )
  '';

  postInstall = ''
    # Entry point — buildPythonApplication wraps this via wrapPythonPrograms
    mkdir -p $out/bin
    cat > $out/bin/negpy <<'PYEOF'
    #!${python3Packages.python.interpreter}
    from negpy.desktop.main import main
    main()
    PYEOF
    chmod +x $out/bin/negpy
    patchShebangs $out/bin/negpy

    # Data files — copied next to the negpy package so get_resource_path()
    # (which walks three levels up from paths.py) finds them.
    site_packages=$out/lib/${python3Packages.python.libPrefix}/site-packages
    cp -r icc media crosstalk gear "$site_packages/"

    # Shader files (*.wgsl) live inside negpy but setuptools won't include
    # non-Python files without package_data config.  Merge them into the
    # installed negpy package so get_resource_path() finds them.
    cp -r negpy/features "$site_packages/negpy/"

    # VERSION file — get_app_version() walks 4 levels up from
    # negpy/kernel/system/version.py to $site_packages/ and reads it there.
    cp VERSION "$site_packages/"

    # Desktop entry
    install -Dm644 negpy.desktop "$out/share/applications/negpy.desktop"
    substituteInPlace "$out/share/applications/negpy.desktop" \
      --replace-fail "Exec=NegPy" "Exec=$out/bin/negpy" \
      --replace-fail "Icon=icon" "Icon=negpy"
    install -Dm644 media/icons/icon.svg "$out/share/icons/hicolor/scalable/apps/negpy.svg"
  '';

  # Tests require GPU and Qt — cannot run in the Nix sandbox.
  doCheck = false;

  meta = with lib; {
    description = "Tool for processing film negatives with film-physics simulation";
    longDescription = ''
      NegPy is a tool for processing film negatives. It simulates how film and
      photographic paper work, going beyond a simple inversion tool by modeling
      the H&D Characteristic Curve in density space — an asymmetric
      toe-linear-shoulder response with independent softplus toe/shoulder knees
      and ISO-R paper grades.

      Features include smart auto conversion, camera scanning, direct scanner
      (SANE) support, dodge & burn, dust removal with grain synthesis, GPU
      acceleration via Vulkan/Metal, full ICC colour management, and export
      presets for printing.
    '';
    homepage = "https://github.com/marcinz606/NegPy";
    changelog = "https://github.com/marcinz606/NegPy/releases/tag/${finalAttrs.version}";
    license = licenses.gpl3Only;
    mainProgram = "negpy";
    maintainers = with maintainers; [];
    platforms = platforms.linux;
  };
})
