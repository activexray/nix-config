{
  DisableTelemetry = true;
  DNSOverHTTPS = {
    Enabled = true;
    ProviderURL = "https://dns.mullvad.net/dns-query";
    # Private names public DoH can't resolve (Tailscale MagicDNS, OVRO internal)
    ExcludedDomains = ["ts.net" "ovro.pvt"];
  };

  # Single switch for all AI features (Firefox 149.0.2+); translations stay on
  AIControls = {
    Default = {
      Value = "blocked";
      Locked = true;
    };
    Translations = {
      Value = "available";
      Locked = false;
    };
  };
  EnableTrackingProtection = {
    Value = true;
    Locked = false;
    Cryptomining = true;
    Fingerprinting = true;
  };

  # Disables the “Import data from another browser” option in the bookmarks window.
  DisableProfileImport = true;
  DisablePocket = true;
  DisableFirefoxStudies = true;
  DisableFirefoxScreenshots = true;
  DontCheckDefaultBrowser = true;
  OfferToSaveLogins = false;
  SearchSuggestEnabled = false;

  # Turn off all the bullshit suggestions
  FirefoxSuggest = {
    Locked = true;
    WebSuggestions = false;
    SponsoredSuggestions = false;
    ImproveSuggest = false;
  };

  DisplayMenuBar = "default-off";

  # Home only shows search
  FirefoxHome = {
    Search = true;
    Locked = false;
    TopSites = false;
    SponsoredTopSites = false;
    Highlights = false;
    # Pocket/SponsoredPocket were renamed in Firefox 141; Snippets removed in 122
    Stories = false;
    SponsoredStories = false;
    Weather = false; # Firefox 152+
    Widgets.Enabled = false; # Firefox 156+
  };

  DisplayBookmarksToolbar = "never"; # I don't even really use bookmarks

  OverrideFirstRunPage = "";
  PictureInPicture.Enabled = false; # I don't ever want this

  HardwareAcceleration = true;
  TranslateEnabled = true;

  # Default start page of previous session
  Homepage.StartPage = "previous-session";

  UserMessaging = {
    UrlbarInterventions = false;
    SkipOnboarding = true;
    ExtensionRecommendations = false;
    FeatureRecommendations = false;
    MoreFromMozilla = false;
  };

  Extensions.Locked = [
    "browserpass@maximbaz.com"
  ];

  # Keep all extension buttons out of the toolbar by default
  ExtensionSettings = {
    "*" = {
      default_area = "menupanel";
    };
  };
}
