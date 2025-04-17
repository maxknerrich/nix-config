# import & decrypt secrets in `mysecrets` in this module
{
  inputs,
  lib,
  config,
  ...
}: {
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

  age.secrets = lib.mkMerge [
    # Global secrets (available on all hosts)
    {
      "hashedUserPassword" = {
        file = "${inputs.mysecrets}/hashedUserPassword.age";
      };
    }

    # Titan-specific secrets
    (lib.mkIf (config.networking.hostName == "titan") {
      "tgCredentials" = {
        symlink = true;
        file = "${inputs.mysecrets}/tgCredentials.age";
        mode = "0400";
        owner = "root";
        group = "root";
      };

      "googleAppPassword" = {
        file = "${inputs.mysecrets}/googleAppPassword.age";
      };

      "fsPWD" = {
        file = "${inputs.mysecrets}/fsPWD.age";
      };
    })
  ];
}
