{
  description = "Kiran's NixOS Config";

  # Sources for all nix flakes that make up the config
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      url = "github:TheTeXnician/nixGL/update-for-latest-nixpkgs";
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
        nixpkgs-nixcord.follows = "nixpkgs";
      };
    };

    # Autoslop
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hardware,
    nixgl,
    determinate,
    nix-doom,
    nur,
    catppuccin,
    nixcord,
    llm-agents,
    ...
  } @ inputs: let
    inherit (self) outputs;

    homeModules = [
      nix-doom.homeModule
      catppuccin.homeModules.catppuccin
      nixcord.homeModules.nixcord
    ];

    nixosModules = [
      determinate.nixosModules.default
      catppuccin.nixosModules.catppuccin
    ];

    overlays = [
      nixgl.overlay
      nur.overlays.default
      (import ./overlays/cockatrice.nix)
      (import ./overlays/negpy.nix)
      llm-agents.overlays.default
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
            extraSpecialArgs = {inherit inputs outputs nixgl;};
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
        specialArgs = {inherit inputs outputs;};
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
          cudaSupport = true;
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
        inherit nixgl;
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
            makeWrapper "${nixgl.packages.x86_64-linux.nixGLDefault}/bin/nixGL" \
              "$out/bin/$(basename $bin)" \
              --add-flags "$bin"
          done
        '';
    in {
      kicad = nixGLWrap (pkgs.kicad-small.override {compressStep = false;});
    };

    # `nix fmt` formatter (also used by the claude-code PostToolUse hook)
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
