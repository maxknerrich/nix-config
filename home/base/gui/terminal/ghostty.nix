{theme, ...}: {
  programs.ghostty = {
    enable = true;
    settings.theme = theme.apps.ghostty;
  };
}
