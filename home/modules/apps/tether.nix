# Tether: iPhone <-> Linux Continuity (clipboard sync, file transfer,
# SMS/iMessage, notifications, OTP autofill).
# https://github.com/zackb/tether
{pkgs, ...}: let
  # `pkgs.tether` (nixpkgs) builds tetherd/tether/tether-gtk and the native
  # messaging manifests, but not the browser/mail extensions
  # (TETHER_BUILD_EXTENSIONS=false upstream) — those ship separately on
  # addons.mozilla.org / addons.thunderbird.net and aren't in the rycee
  # firefox-addons NUR repo yet, so we package the two xpis ourselves.
  #
  # Both extensions share one gecko id (tether@tether.com); tether's native
  # messaging manifest allow-lists exactly that id. Firefox and Thunderbird
  # both look for extensions at share/mozilla/extensions/{toolkit-app-id}/
  # inside the package — this is the same layout home-manager's own
  # extensions.packages/extensions options expect.
  buildTetherAddon = {
    pname,
    url,
    hash,
  }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname;
      version = "1.0.6";
      src = pkgs.fetchurl {inherit url hash;};
      dontUnpack = true;
      installPhase = ''
        dest="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dest"
        cp "$src" "$dest/tether@tether.com.xpi"
      '';
    };

  firefoxAddon = buildTetherAddon {
    pname = "tether-browser-extension";
    url = "https://addons.mozilla.org/firefox/downloads/latest/tether-browser-extension/latest.xpi";
    hash = "sha256-DyN8ANYMQ0Pn4PJQwlxLWv8Ftqk/nZ0vluwOCuWiRxc=";
  };

  thunderbirdAddon = buildTetherAddon {
    pname = "tether-mail-extension";
    url = "https://addons.thunderbird.net/thunderbird/downloads/latest/tether-mail-extension/latest.xpi";
    hash = "sha256-l7TVitSocUq1Efgsi7PUsWvKULx43QfNAqHANF7INZw=";
  };
in {
  home.packages = [pkgs.tether];

  # Run the daemon in the graphical session so it's always available for
  # clipboard sync/notifications, same as upstream's documented
  # `systemctl --user enable --now tetherd.service` (not shipped by the
  # nixpkgs package itself).
  systemd.user.services.tetherd = {
    Unit = {
      Description = "Tether daemon (iPhone/Linux Continuity)";
      Documentation = "man:tetherd(8)";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.tether}/bin/tetherd";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Native messaging hosts: on Linux, Firefox and Thunderbird share
  # ~/.mozilla/native-messaging-hosts, so either option alone would do it,
  # but setting both keeps this working if one app is ever dropped.
  programs.firefox.nativeMessagingHosts = [pkgs.tether];
  programs.thunderbird.nativeMessagingHosts = [pkgs.tether];

  # Force-installed like the other declaratively-managed extensions. This
  # matters here specifically because profile.nix sets
  # `extensions.force = true`, which replaces the whole profile extensions/
  # directory from this list on every switch — an extension installed by
  # hand from the addon store would just get deleted on the next rebuild.
  programs.firefox.profiles.default.extensions.packages = [firefoxAddon];
  programs.thunderbird.profiles.default.extensions = [thunderbirdAddon];
}
