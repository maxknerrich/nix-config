{my, ...}: let
  sshSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMU+MXkqxIDEg9IPVCluImSjRByx71QCQdveLQNifwGq ${my.email}";
in {
  programs.git = {
    enable = true;
    ignores = [".DS_Store"];
    lfs.enable = true;
    settings = {
      user = {
        name = my.fullUsername;
        email = my.email;
        signingKey = sshSigningKey;
      };
      init.defaultBranch = "main";
      commit.gpgSign = true;
      tag.gpgSign = true;
      gpg.format = "ssh";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
}
