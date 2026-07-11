# CLI and utility packages
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Very important
    cowsay
    lolcat

    # utils
    ripgrep
    grc
    fd
    tealdeer
    tmux
    pciutils
    alejandra
    (aspellWithDicts (
      dicts:
        with dicts; [
          en
          en-computers
          en-science
        ]
    ))
    unzip
    dosfstools
    mtools
    cachix
    usbutils
    iperf3
    htop
    helix
    nix-output-monitor

    # Wine
    wineWow64Packages.stable
    winetricks

    # nix tools
    any-nix-shell
    nil

    # documents
    pdf2svg
    poppler
    typst
    typstyle

    # build tools
    ninja
    cmake

    # science/data
    julia-bin
  ];
}
