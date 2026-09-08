# QtPass settings.
#
# QtPass persists both its config (recipient/executable paths) and its
# window-manager state (geometry, dialog positions) in the same QSettings
# ini file, and rewrites that whole file on every exit. Managing it with
# xdg.configFile would make it a read-only store-path symlink and qtpass
# would lose its window state on every launch, so instead we patch just the
# keys we care about into the file in place, leaving the rest (and the file
# itself, if qtpass hasn't run yet) alone.
{
  pkgs,
  config,
  lib,
  ...
}: {
  # qtpass's actual $SSH_AUTH_SOCK at launch depends on how the desktop
  # session propagates it, which on GNOME races against (and sometimes
  # loses to) GNOME Keyring's own ssh-agent, leaving qtpass's git ssh
  # operations pointed at an agent that doesn't have the yubikey. Wrap it
  # to resolve gpg-agent's ssh socket itself at launch instead of trusting
  # whatever the session handed it.
  home.packages = [
    (pkgs.symlinkJoin {
      name = "qtpass";
      paths = [(config.lib.nixGL.wrap pkgs.qtpass)];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/qtpass \
          --run 'export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"'
      '';
    })
  ];

  home.activation.qtpassSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    conf="${config.xdg.configHome}/IJHack/QtPass.conf"
    mkdir -p "$(dirname "$conf")"
    touch "$conf"

    # New Folder in the qtpass UI otherwise writes a .gpg-id populated from
    # whatever keys are checked "enabled" in the recipients list -- none by
    # default -- producing an empty .gpg-id and "no valid addressees" on the
    # next encrypt. With this off, new folders get no .gpg-id at all and
    # inherit the parent's, same as every other folder in the store.
    ${pkgs.crudini}/bin/crudini --set "$conf" General addGPGId false
  '';
}
