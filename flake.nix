{
  description = "Kira's NixOS Config";

  # Sources for all nix flakes that make up the config
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware Definitions
    hardware.url = "github:NixOS/nixos-hardware";

    # NixGL
    nixgl = {
      # nix-community/nixGL#226 (aggregate of open PRs); #227 is patched in below
      url = "github:catouc/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate Nix
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    # Doom Emacs
    nix-doom = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    # Catppuccin Everything
    catppuccin.url = "github:catppuccin/nix";

    # Unfucked Discord
    nixcord = {
      url = "github:FlameFlag/nixcord";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # Autoslop
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # negpy
    negpy = {
      url = "github:marcinz606/NegPy";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    hardware,
    nixgl,
    determinate,
    nix-doom,
    nur,
    catppuccin,
    nixcord,
    llm-agents,
    negpy,
    ...
  } @ inputs: let
    inherit (self) outputs;

    stablePkgs = import nixpkgs-stable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    homeModules = [
      nix-doom.homeModule
      catppuccin.homeModules.catppuccin
      nixcord.homeModules.nixcord
    ];

    nixosModules = [
      determinate.nixosModules.default
      catppuccin.nixosModules.catppuccin
    ];

    # nixGL with nix-community/nixGL#227 (pcregrep -> pcre2grep; nixpkgs
    # removed pcre) applied. nixgl.packages can't be patched in place, so
    # rebuild it the same way nixGL's flake.nix does.
    nixgl' = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      src = pkgs.applyPatches {
        name = "nixGL-patched";
        src = nixgl;
        patches = [
          (pkgs.fetchpatch {
            url = "https://github.com/happy-dude/nixGL/commit/320297bd99179701d63e3670e64e636d6165afe2.patch";
            hash = "sha256-WXuqzULt5sXe0LKgYYP7Vqbu87BHlKQfFthl/29/MlA=";
          })
        ];
      };
      gl = import "${src}/default.nix" {
        inherit pkgs;
        enable32bits = true;
        enableIntelX86Extensions = true;
      };
    in
      nixgl
      // {
        packages.x86_64-linux = rec {
          default = nixGLDefault;
          nixGLDefault = gl.auto.nixGLDefault;
          nixGLNvidia = gl.auto.nixGLNvidia;
          nixGLNvidiaBumblebee = gl.auto.nixGLNvidiaBumblebee;
          nixGLIntel = gl.nixGLIntel;
          nixVulkanNvidia = gl.auto.nixVulkanNvidia;
          nixVulkanIntel = gl.nixVulkanIntel;
        };
      };

    overlays = [
      nur.overlays.default
      (import ./overlays/cockatrice.nix)
      (import ./overlays/neocmakelsp.nix)
      llm-agents.overlays.shared-nixpkgs
    ];

    # A function to automatically set the hostname and hostname-derived config
    commonModules = name:
      [
        ./nixos/common
        {networking.hostName = name;}
        {nixpkgs.overlays = overlays;}
        {
          home-manager = {
            # Just pass the whole input output sets to HM
            extraSpecialArgs = {
              inherit inputs outputs stablePkgs;
              nixgl = nixgl';
            };
            useUserPackages = true;
            useGlobalPkgs = true;
            backupFileExtension = "backup";
            sharedModules = homeModules;
            users = {
              kiran = import ./home/${name}.nix;
            };
          };
        }
        ./nixos/${name}
      ]
      ++ nixosModules;

    # A function to create the NixOS systems
    mkSystem = name: cfg:
      nixpkgs.lib.nixosSystem {
        system = cfg.system or "x86_64-linux";
        modules = (commonModules name) ++ (cfg.modules or []);
        specialArgs = {inherit inputs outputs stablePkgs;};
      };

    # The systems we'll configure
    systems = {
      # My home desktop
      kix = {};
      # My framework laptop
      kixtop = {};
    };
  in {
    # Build the systems for NixOS
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem systems;

    # Provide the home configuration for non-nixOS work machine
    homeConfigurations."kshila" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
          # onlyoffice-desktopeditors still needs gtk2 (nixpkgs#410814)
          problems.handlers."gtk+".broken = "warn";
        };
        overlays = overlays;
      };

      # The home-config for the standalone install
      modules =
        [
          ./home/krocky.nix
        ]
        ++ homeModules;

      # Passing along nixgl to the standalone
      extraSpecialArgs = {
        inherit stablePkgs;
        nixgl = nixgl';
      };
    };

    # Exported packages: custom derivations and nixGL-wrapped apps
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = overlays;
      };
      nixGLWrap = pkg:
        pkgs.runCommand "${pkg.name}-nixgl-wrapped" {
          nativeBuildInputs = [pkgs.makeWrapper];
        } ''
          mkdir -p $out/bin
          for bin in ${pkg}/bin/*; do
            makeWrapper "${nixgl'.packages.x86_64-linux.nixGLDefault}/bin/nixGL" \
              "$out/bin/$(basename $bin)" \
              --add-flags "$bin"
          done
        '';
    in {
      # flake outputs so we can nix run .#whatever
      # kicad = nixGLWrap (pkgs.kicad-small.override {compressStep = false;});
      # negpy = nixGLWrap pkgs.negpy;
    };

    # `nix fmt` formatter (also used by the claude-code PostToolUse hook)
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
