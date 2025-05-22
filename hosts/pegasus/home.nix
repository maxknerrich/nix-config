{pkgs, ...}: {
  programs.vscode.enable = true;
  programs.kitty.enable = true;
  programs.firefox.enable = true;

  home.packages = with pkgs; [
    _1password-gui
    zotero
    ghostty
  ];
}
