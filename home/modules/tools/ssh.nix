# SSH Config
{...}: {
  # Copy in the yubikey ssh public key to use as an explicit identity
  # This is ok to live in the nix store because, public key
  # Normally you'd not do this for a private key
  home.file.".ssh/id_rsa_yubikey.pub" = {
    source = ../../../assets/id_rsa_yubikey.pub;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/id_rsa_yubikey.pub";
        # Always use gpg-agent, even when the session's SSH_AUTH_SOCK points
        # elsewhere (GNOME keyring on Rocky is started by PAM and wins in GUI apps)
        IdentityAgent = "\${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh";
      };

      "ovro" = {
        HostName = "ssh.ovro.caltech.edu";
        User = "kiran";
      };

      "grex" = {
        HostName = "grex-ovro.ovro.pvt";
        ProxyJump = "ovro";
        User = "user";
      };

      "github.com" = {
        User = "git";
      };

      "sprite" = {
        User = "sprite";
        HostName = "turtle.ovro.pvt";
        ProxyJump = "ovro";
      };

      "mvp03" = {
        User = "kshila";
        HostName = "mvp03mncopl.ovro.pvt";
        ProxyJump = "ovro";
        DynamicForward = [{port = 1080;}];
      };

      "ant1" = {
        User = "antovro";
        HostName = "dsa-raspi-cm4-0001.ovro.pvt";
        ProxyJump = "ovro";
      };

      "ant6" = {
        User = "antovro";
        HostName = "dsa-raspi-cm4-0002.ovro.pvt";
        ProxyJump = "ovro";
      };
    };
  };
}
