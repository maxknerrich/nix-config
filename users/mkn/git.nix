{...}: {
  programs.git = {
    enable = true;
    userName = "Max Knerrich";
    userEmail = "max.knerrich@outlook.com";
    extraConfig.init.defaultBranch = "main";
  };
}
