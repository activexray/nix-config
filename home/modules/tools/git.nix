# Git config
{pkgs, ...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      key = null;
      signByDefault = true;
    };
    settings = {
      user = {
        email = "me@kiranshila.com";
        name = "Kiran Shila";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = true;
      };
      # nixpkgs' git is built against its own openssh (currently 10.5p1),
      # patched in as a runtime-closure-pinned absolute path, bypassing
      # $PATH entirely. On Rocky that pinned build doesn't understand the
      # GSSAPIKexAlgorithms directive dnf's crypto-policies package writes
      # for the system openssh it tracks (9.9p1), so every git ssh
      # operation fails with "Bad configuration option: gssapikexalgorithms".
      #
      # A bare "ssh" isn't enough to route around it: pass's generated
      # wrapper (programs.password-store) prepends its own dependency
      # closure -- including that same nix-store openssh -- onto $PATH
      # ahead of /usr/bin, so PATH-based lookup still finds the broken
      # build. Use an absolute path to the distro ssh where one exists
      # (Rocky), bypassing $PATH entirely; on NixOS hosts (no /usr/bin/ssh)
      # fall back to PATH lookup, where everything is one consistent
      # nixpkgs closure and this mismatch can't happen.
      core.sshCommand =
        if builtins.pathExists "/usr/bin/ssh"
        then "/usr/bin/ssh"
        else "ssh";
      diff.tool = "difftastic";
      difftool.difftastic.cmd = "${pkgs.difftastic}/bin/difft --color=always $LOCAL $REMOTE";
      alias.dft = "difftool";
    };
  };

  # Enable difftastic as a CLI tool (not as git's external diff driver, which breaks Magit)
  programs.difftastic = {
    enable = true;
  };
}
