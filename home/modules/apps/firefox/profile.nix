{
  lib,
  pkgs,
  config,
  ...
}: {
  id = 0;
  isDefault = true;
  userChrome = builtins.readFile ./userChrome.css;

  settings = {
    "browser.profiles.enabled" = false; # FIXME: https://github.com/nix-community/home-manager/issues/6934
    "privacy.resistFingerprinting" = false;
    "privacy.clearOnShutdown.history" = false;
    "privacy.clearOnShutdown.downloads" = false;
    "browser.startup.page" = 3;
    "middlemouse.paste" = false;
    "general.autoScroll" = true;
    "identity.fxaccounts.enabled" = true;

    "browser.download.autohideButton" = true;
    "browser.uiCustomization.state" = builtins.toJSON {
      placements = {
        widget-overflow-fixed-list = ["new-tab-button" "alltabs-button"];
        unified-extensions-area = [
          "contaner-proxy_bekh-ivanov_me-browser-action"
          "jid1-zadieub7xozojw_jetpack-browser-action"
          "_contain-facebook-browser-action"
          "browserpass_maximbaz_com-browser-action"
          "zotero_chnm_gmu_edu-browser-action"
          "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
          "ublock0_raymondhill_net-browser-action"
          "sponsorblocker_ajay_app-browser-action"
        ];
        nav-bar = [
          "back-button"
          "forward-button"
          "stop-reload-button"
          "vertical-spacer"
          "urlbar-container"
          "downloads-button"
          "unified-extensions-button"
        ];
        toolbar-menubar = ["menubar-items"];
        TabsToolbar = [];
        vertical-tabs = ["tabbrowser-tabs"];
        PersonalToolbar = ["personal-bookmarks"];
      };
      seen = [
        "developer-button"
        "contaner-proxy_bekh-ivanov_me-browser-action"
        "jid1-zadieub7xozojw_jetpack-browser-action"
        "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
        "_contain-facebook-browser-action"
        "ublock0_raymondhill_net-browser-action"
        "browserpass_maximbaz_com-browser-action"
        "zotero_chnm_gmu_edu-browser-action"
        "sponsorblocker_ajay_app-browser-action"
      ];
      dirtyAreaCache = ["nav-bar" "PersonalToolbar" "unified-extensions-area" "toolbar-menubar" "TabsToolbar" "vertical-tabs"];
      currentVersion = 23;
      newElementCount = 2;
    };
    "browser.aboutConfig.showWarning" = false;
    "browser.urlbar.keepPanelOpenDuringImeComposition" = true;

    # Auto enable the extensions
    "extensions.autoDisableScopes" = 0;
    "extensions.update.autoUpdateDefault" = false;
    "extensions.update.enabled" = false;

    # Enable custom stylesheet
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Calculator in URL bar
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.unitConversion.enabled" = true;

    # Rouund
    "widget.gtk.rounded-bottom-corners.enabled" = true;

    "browser.compactmode.show" = true;
    "browser.tabs.allow_transparent_browser" = false;
    "browser.uidensity" = 1;

    # Sidebar
    "sidebar.revamp" = true;
    "sidebar.verticalTabs" = true;
    "sidebar.visibility" = "expand-on-hover";

    # Sync Login
    "services.sync.username" = "me@kiranshila.com";
    # Only sync history, bookmarks, tabs
    "services.sync.declinedEngines" = "addresses,addons,passwords,creditcards,prefs";
    "services.sync.engine.addons" = false;
    "services.sync.engine.addresses" = false;
    "services.sync.engine.prefs" = false;
    "services.sync.engine.creditcards" = false;
    "services.sync.engine.passwords" = false; # We're using Pass

    # Open PDFs inline
    "browser.download.open_pdf_attachments_inline" = true;

    # Non-NixOS: loading system CA roots via NSS trust_anchors::pkcs11 fails
    # mid-handshake on RHEL 9, producing SEC_ERROR_LIBRARY_FAILURE on affected sites.
    "security.enterprise_roots.enabled" = false;

    # Pls no AI
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.page.footerBadge" = false;
    "browser.ml.chat.page.menuBadge" = false;
    "browser.ml.chat.shortcuts" = false;
    "browser.ml.chat.shortcuts.custom" = false;
    "browser.ml.chat.sidebar" = false;
    "browser.ml.checkForMemory" = false;
    "browser.ml.enable" = false;
    "browser.ml.linkPreview.shift" = false;
  };

  search = {
    force = true;
    default = "ddg";
    privateDefault = "ddg";
    engines = {
      # Disable all the stupid "This time, search with" icons
      bing.metaData.hidden = true;
      ebay.metaData.hidden = true;
      wikipedia.metaData.hidden = true;
      perplexity.metaData.hidden = true;

      "Nix Packages" = {
        urls = [
          {
            template = "https://search.nixos.org/packages";
            params = [
              {
                name = "channel";
                value = "unstable";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = ["@np"];
      };

      "Nix Options" = {
        urls = [
          {
            template = "https://search.nixos.org/options";
            params = [
              {
                name = "channel";
                value = "unstable";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = ["@no"];
      };

      "NixOS Wiki" = {
        urls = [
          {
            template = "https://wiki.nixos.org/w/index.php";
            params = [
              {
                name = "search";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = ["@nw"];
      };
    };
  };

  extensions = {
    force = true;
    packages = with pkgs.nur.repos.rycee.firefox-addons; [
      ublock-origin
      sponsorblock
      duckduckgo-privacy-essentials
      facebook-container
      zotero-connector
      privacy-badger
      browserpass
      container-proxy
    ];
    # Extension-specific settings
    settings = {};
  };
}
