{pkgs, ...}: let
  type = "caldav";
  userName = "me@4ktb.xyz";
  urlRoot = "https://cdav.migadu.com/calendars/${userName}";
  passwordCommand = "${pkgs.pass}/bin/pass migadu.com/${userName}";
in {
  accounts.calendar.accounts = {
    Home = {
      remote = {
        inherit type userName passwordCommand;
        url = "${urlRoot}/home";
      };
      thunderbird.enable = true;
    };
    Work = {
      remote = {
        inherit type userName passwordCommand;
        url = "${urlRoot}/work";
      };
      thunderbird.enable = true;
    };
  };
}
