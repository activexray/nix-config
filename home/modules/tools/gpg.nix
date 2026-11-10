{
  pkgs,
  lib,
  ...
}: {
  # Configure gpg
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = false; # Enable CCID smartcard support (don't disable it)
    };
    # Import my public key and give it ultimate trust
    publicKeys = [
      {
        source = ../../../assets/publickey.gpg;
        trust = "ultimate";
      }
    ];

    # From Dr Duh
    settings = {
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;
      # Prevent gpg from auto-launching a daemon agent. home-manager's
      # publicKeys activation runs in a system service before the user
      # systemd session is ready, which would otherwise spawn a second
      # gpg-agent daemon that conflicts with the socket-activated one.
      no-autostart = true;
    };
  };

  # GnuPG 2.4 writes `use-keyboxd` here on fresh homedirs. With no-autostart
  # above, gpg then can't reach keyboxd unless it's started by hand. Pin the
  # file empty so every machine uses pubring.kbx.
  home.file.".gnupg/common.conf" = {
    text = "";
    force = true;
  };

  # Setup GPG Agent
  # Following Dr. Duh
  # https://raw.githubusercontent.com/drduh/config/master/gpg-agent.conf
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    defaultCacheTtl = 60;
    maxCacheTtl = 120;
    pinentry.package = lib.mkDefault pkgs.pinentry-qt;
    enableScDaemon = true;
  };
}
