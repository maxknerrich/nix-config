{...}: {
  programs.git = {
    enable = true;
    userName = "Max Knerrich";
    userEmail = "maxknerrich@outlook.com";
    extraConfig.init.defaultBranch = "main";
  };
}
