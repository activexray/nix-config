# Common NixOS system config to be inherited by all systems
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Bring in home manager
    inputs.home-manager.nixosModules.home-manager
  ];

  # Configure the bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    systemd-boot.configurationLimit = 10;
  };

  # Enable all the firmware
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # Set the interpreter for AppImages
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  # Setup networking and syncthing ports
  networking = {
    networkmanager.enable = true;
    # Syncthing ports:
    # 22000 TCP and/or UDP for sync traffic
    # 21027/UDP for discovery
    # source: https://docs.syncthing.net/users/firewall.html
    firewall.allowedTCPPorts = [22000];
    firewall.allowedUDPPorts = [
      22000
      21027
    ];
    # MagicDNS for tailscale
    nameservers = [
      "100.100.100.100"
      "1.1.1.1"
      "8.8.8.8"
    ];
    search = ["tail297143.ts.net"];
  };

  # Setup time
  time.timeZone = "America/Los_Angeles";

  # Locale Chaos
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  # X Server Setup (KDE Plasma and SDDM)
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Use SDDM
  services.displayManager.sddm = {
    enable = true;
  };

  # Use KDE Plasma 6
  services.desktopManager = {
    plasma6.enable = true;
  };

  # OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Linux <3 Sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # Nixpkgs Configuration
  nixpkgs = {
    # Configure your nixpkgs instance to allow unfree
    # Sorry, RMS
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) (
    (lib.filterAttrs (_: lib.isType "flake")) inputs
  );

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Perform garbage collection weekly to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  nix.settings = {
    # Enable flakes and new 'nix' command
    # This should be default now with determinate nix
    #experimental-features = ["nix-command" "flakes"];
    # Determinate Nix-specific features
    extra-experimental-features = "parallel-eval";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
    # Allow me to specify additional substituters
    trusted-users = ["kiran" "kshila"];
    # List of substituters
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://kiranshila.cachix.org"
      "https://cache.numtide.com"
      "https://cache.nixos-cuda.org"
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "kiranshila.cachix.org-1:S0sidekrlCDb6OdMXMuzj6l6UdI32SyrHBBfAVkA8Mk="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "cuda-maintainers.cachix.org-1:cc5BfG5nG4s2KB41FttLbB3PRz9sENdSB1sGncPcC2E="
    ];
  };

  users = {
    # Define the plugdev group
    groups.plugdev = {};
    # Kiran is always the default user
    users = {
      kiran = {
        isNormalUser = true;
        description = "Kiran Shila";
        extraGroups = [
          "wheel"
          "networkmanager"
          "plugdev"
          "libvirtd"
          "dialout"
        ];
      };
    };
  };

  # Security
  security.rtkit.enable = true;

  # Launch fish unless the parent process is fish (keeping bash as system shell)
  # This gets around a bug with fish not being quite posix
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # Fish!
  programs.fish = {
    enable = true;
    useBabelfish = true; # Much better startup time
  };

  programs.command-not-found.enable = false; # Broken with fish

  # Some barebones programs everyone needs
  environment.systemPackages = with pkgs; [
    wget
    curl
    vim
    libusb1
    # iPhone
    libimobiledevice
    ifuse
  ];

  # Use /var/tmp instead of the default to get more than the RAM size for nix builds
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

  # Support iPhone tethering, etc
  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  # Set the default editor to vim
  environment.variables.EDITOR = "vim";

  # Make dirty binaries "just work"
  programs.nix-ld.enable = true;

  # Enable hardware support for yubikey/smartcards
  hardware.gpgSmartcards.enable = true;

  # Enables GnuPG agent with socket-activation for every user session.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Enable steam
  # NOTE: This is system-level because of how steam needs 32-bit binaries,
  # which must be installed systemwide
  programs.steam.enable = true;

  # Enable Xbox One controller drivers
  hardware.xone.enable = true;

  # Enable partition manager (needs dbus, so system-level)
  programs.partition-manager.enable = true;

  # Udev rules for USB things like tigard
  services.udev.extraRules = let
    # Grant plugdev access to a USB vendor
    usbVendor = vendor: ''SUBSYSTEM=="usb", ATTR{idVendor}=="${vendor}", GROUP="plugdev", MODE="0666"'';
  in
    lib.concatMapStringsSep "\n" usbVendor [
      "0403" # FTDI
      "f4ec" # Siglent
      "2817" # Signal Hound
      "1a0d" # LadyBug
      "20ce" # MiniCircuits
      "3923" # National Instruments
      "0aad" # Rohde & Schwarz
      "1366" # Jlink
      "0cd5" # LabJack
      "0765" # X-Rite i1 Display Pro
      "320f" # Rainy75 Keyboard
      "2e8a" # PicoProbe
    ]
    + ''

      # 8BitDo Ultimate Bluetooth Controller (boot HID + receiver)
      SUBSYSTEM=="hidraw", ATTRS{idProduct}=="3208", ATTRS{idVendor}=="2dc8", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idProduct}=="3109", ATTRS{idVendor}=="2dc8", TAG+="uaccess"
      # Give hidraw access to all of plugdev
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", GROUP="plugdev", MODE="0666", TAG+="uaccess"
    '';

  # Enable fwupmgr
  services.fwupd.enable = true;

  # NAS NFS mount — automounts on access, fails fast when unreachable (safe for laptop)
  fileSystems."/mnt/storage" = {
    device = "192.168.4.202:/volume1/storage";
    fsType = "nfs";
    options = [
      "nfsvers=4.1"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "soft"
      "timeo=30" # 3s before retrying
      "retrans=2"
    ];
  };

  # Enable Zram swap
  zramSwap.enable = true;

  # Catppuccin NixOS (only handles a few things that are sytem-level)
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "macchiato";
  };

  # Printer setup
  services = {
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  # Tailscale
  services.tailscale.enable = true;
}
