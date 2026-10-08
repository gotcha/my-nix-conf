{ ... }:
{
  # Voice input desired state. Applied as the console (primary) user at activation
  # via system.defaults (per-user `defaults write`).
  #
  # One-time steps nix cannot do, because Apple owns them behind UI:
  #   - Voice Control first run: Settings > Accessibility > Voice Control on once
  #     (confirms + downloads the on-device language model for the locale). The
  #     CommandAndControlEnabled flag below keeps it pinned on afterwards.
  #   - On-device dictation model for en_GB: downloaded by clicking the language
  #     in Settings > Keyboard > Dictation while online. After that, offline.
  # Auto-punctuation lives inside "Offline Dictation Status" (per-locale, written
  # by the OS with asset state) — deliberately NOT pinned here to avoid clobbering
  # system-owned dictionaries with whole-dict activation writes.
  system.defaults.CustomUserPreferences = {
    "com.apple.assistant.support" = {
      "Dictation Enabled" = true;
    };
    # English-only dictation: fr_BE was removed (no offline support).
    # Note: the dictation-language UI rewrites DictationIMPreferredLanguageIdentifiers
    # at runtime; activation re-pins this list each rebuild.
    "com.apple.speech.recognition.AppleSpeechRecognition.prefs" = {
      DictationIMPreferredLanguageIdentifiers = [ "en_GB" ];
      DictationIMNetworkBasedLocaleIdentifier = "en_GB";
    };
    "com.apple.Accessibility" = {
      CommandAndControlEnabled = true; # Voice Control
    };
    # Globe key: 3 = "Start Dictation (press globe twice)".
    # mapping: https://macos-defaults.com/keyboard/applefnusagetype.html
    # "press twice" wording: https://support.apple.com/guide/mac-help/use-dictation-to-enter-text-mh40584/mac
    "com.apple.HIToolbox" = {
      AppleFnUsageType = 3;
    };
  };
}
