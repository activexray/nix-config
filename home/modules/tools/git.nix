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
