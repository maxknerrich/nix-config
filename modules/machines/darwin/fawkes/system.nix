{
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      ShowStatusBar = true;
    };
    trackpad.Clicking = true;
    dock = {
      show-recents = false;
      persistent-apps = [
        # Daily apps pinned left-to-right.
        "/Applications/Zed.app"
        "/Applications/Zen.app"
        "/Applications/Ghostty.app"
        "/Applications/Timemator.app"
      ];
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true; # Allow Touch ID for sudo.
}
