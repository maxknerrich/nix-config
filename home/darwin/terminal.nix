{my, ...}: {
  programs.ghostty = {
    package = null; # App is installed by Homebrew; HM writes config only.
    settings = {
      command = "/etc/profiles/per-user/${my.username}/bin/fish";
      macos-option-as-alt = "left";
    };
  };
}
