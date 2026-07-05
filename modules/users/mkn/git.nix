{my, ...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = my.fullUsername;
        email = my.email;
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
}
