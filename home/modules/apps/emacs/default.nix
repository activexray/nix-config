{
  pkgs,
  lib,
  ...
}: let
  # These follow from clojure-ts-grammar-recipes
  # See: https://github.com/clojure-emacs/clojure-ts-mode/blob/ba6de87b0acb5aa5483f6012611b30f6bf0414f3/clojure-ts-mode.el#L3074
  clojure-ts-grammar = pkgs.tree-sitter.buildGrammar {
    language = "clojure";
    version = "unstable-20250526";
    src = pkgs.fetchFromGitHub {
      owner = "sogaiu";
      repo = "tree-sitter-clojure";
      rev = "69070d2e4563f8f58c7f57b0c8e093a08d7a5814";
      sha256 = "sha256-+Miraf8kI8rZg7SYdfNM+mb78k9xNDUKYg3VTFzUHMo=";
    };
  };

  regex-grammar = pkgs.tree-sitter.buildGrammar rec {
    language = "regex";
    version = "0.24.3";
    src = pkgs.fetchFromGitHub {
      owner = "tree-sitter";
      repo = "tree-sitter-regex";
      tag = "v${version}";
      sha256 = "sha256-GNWntm8sgqVt6a+yFVncjkoMOe7CnXX9Qmpwy6KcFyU=";
    };
  };

  # Required by typst-ts-mode
  typst-grammar = pkgs.tree-sitter.buildGrammar rec {
    language = "typst";
    version = "nightly";
    src = pkgs.fetchFromGitHub {
      owner = "uben0";
      repo = language;
      rev = "master";
      sha256 = "sha256-s/9R3DKA6dix6BkU4mGXaVggE4bnzOyu20T1wuqHQxk=";
    };
  };

  # Required by scad-ts-mode
  scad-grammar = pkgs.tree-sitter.buildGrammar rec {
    language = "openscad";
    version = "0.7.1";
    src = pkgs.fetchFromGitHub {
      owner = "openscad";
      repo = "tree-sitter-openscad";
      rev = "v${version}";
      sha256 = "sha256-2+Ii4uqqmFkuRQEarCUY7dNaR2uk3cvcWleE91Gs5a8=";
    };
  };

  # Required by spade-ts-mode (doom/spade-ts-mode.el). Newer than nixpkgs'
  # tree-sitter-spade; same commit the Zed extension's highlight queries target.
  spade-grammar = pkgs.tree-sitter.buildGrammar {
    language = "spade";
    version = "unstable-2026-06-22";
    src = pkgs.fetchFromGitea {
      domain = "codeberg.org";
      owner = "spade-lang";
      repo = "tree-sitter-spade";
      rev = "d094381a5b3ad7fbff9dc850471479a391b62d1f";
      hash = "sha256-CF3ZDeG359PgMMvD0AfjPMvWj6egIJJ/6g1tK73B0Bc=";
    };
  };
in {
  # Doom Emacs
  programs.doom-emacs = {
    enable = true;
    doomDir = ./doom;
    emacs = lib.mkDefault pkgs.emacs-pgtk; # Default to pure-gtk on wayland builds
    extraPackages = epkgs:
      with epkgs; [
        vterm
        pdf-tools
        (treesit-grammars.with-grammars
          (p:
            with p; [
              # Things from nixpkgs
              tree-sitter-bash
              tree-sitter-nix
              tree-sitter-fish
              tree-sitter-c
              tree-sitter-cpp
              tree-sitter-yaml
              tree-sitter-toml
              tree-sitter-json
              tree-sitter-python
              tree-sitter-rust
              tree-sitter-javascript
              tree-sitter-typescript
              tree-sitter-markdown
              tree-sitter-markdown-inline
              tree-sitter-julia
              tree-sitter-html
              # Our custom ones
              regex-grammar
              clojure-ts-grammar
              typst-grammar
              scad-grammar
              spade-grammar
            ]))
      ];
    experimentalFetchTree = true;
  };

  # Emacs-required packages
  home.packages = with pkgs; [
    # Tools (ripgrep/fd come from tools/cli.nix)
    jq

    # Fonts
    emacs-all-the-icons-fonts
    nerd-fonts.symbols-only

    # LSPs
    taplo # TOML
    clojure-lsp # Clojure
    texlab # LaTeX
    ruff # Python linting
    pyright # Python
    yaml-language-server # YAML
    typescript-language-server # TS/JS
    openscad-lsp # OpenSCAD
    tinymist # Typst
    neocmakelsp # CMake
  ];
}
