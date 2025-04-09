# import & decrypt secrets in `mysecrets` in this module
{inputs, ...}: {
  # DIDN'T WORK CAUSE OF CIRCULAR DEPENDENCY
  # imports = [
  #   agenix.nixosModules.default
  # ];

  # if you changed this key, you need to regenerate all encrypt files from the decrypt contents!
  age.identityPaths = [
    # using the host key for decryption
    # the host key is generated on every host locally by openssh, and will never leave the host.
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  age.secrets."tgCredentials" = {
    # whether secrets are symlinked to age.secrets.<name>.path
    symlink = true;
    # target path for decrypted file
    # path = "/etc/titan"; gave an error
    # encrypted file path
    file = "${inputs.mysecrets}/tgCredentials.age"; # refer to ./xxx.age located in `mysecrets` repo
    mode = "0400";
    owner = "root";
    group = "root";
  };
  age.secrets."hashedUserPassword" = {
    file = "${inputs.mysecrets}/hashedUserPassword.age";
  };
  age.secrets."googleAppPassword" = {
    file = "${inputs.mysecrets}/googleAppPassword.age";
  };
  age.secrets."fsPWD" = {
    file = "${inputs.mysecrets}/fsPWD.age";
  };
}
