let
  mkn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMU+MXkqxIDEg9IPVCluImSjRByx71QCQdveLQNifwGq Max";
in {
  "kronos-luks.age".publicKeys = [mkn];
}
