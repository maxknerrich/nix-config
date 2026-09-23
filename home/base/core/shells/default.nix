{
  pkgs,
  theme,
  ...
}: {
  home.packages = with pkgs; [
    mosh
    tree
  ];

  programs = {
    fish = {
      enable = true;
      shellAliases = {
        ls = "eza -l --group-directories-first";
        l = "eza -l --group-directories-first";
        ll = "eza -lah --group-directories-first --git";
        la = "eza -a --group-directories-first";
        lt = "eza --tree --level=2 --group-directories-first";
        tree = "eza --tree --group-directories-first";
        cat = "bat --paging=never";
        less = "bat --paging=always";
        cd = "z";
        cdi = "zi";
        back = "z -";
      };
    };

    bat = {
      enable = true;
      config = {
        theme = theme.apps.bat;
        style = "numbers,changes,header";
        paging = "never";
      };
    };
    eza = {
      enable = true;
      enableFishIntegration = true;
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
