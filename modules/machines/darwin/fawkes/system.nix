{
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      AppleScrollerPagingBehavior = true;
      AppleIconAppearanceTheme = "RegularAutomatic";
      AppleInterfaceStyle = null;
      AppleInterfaceStyleSwitchesAutomatically = true;
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.12;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Other";
      NewWindowTargetPath = "file:///Users/mkn/Downloads";
      ShowExternalHardDrivesOnDesktop = false;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = false;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
    controlcenter.BatteryShowPercentage = true;
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.12;
      expose-animation-duration = 0.12;
      launchanim = false;
      mineffect = "scale";
      minimize-to-application = true;
      show-recents = false;
      persistent-apps = [
        # Daily apps pinned left-to-right.
        "/Applications/Zed.app"
        "/Applications/Zen.app"
        "/Applications/Ghostty.app"
        "/Applications/Timemator.app"
      ];
    };
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleActionOnDoubleClick = "Fill";
      };
      "com.apple.finder".FXEnableRemoveFromICloudDriveWarning = false;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true; # Allow Touch ID for sudo.
}
