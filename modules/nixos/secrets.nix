# Runtime secrets by name. A secret is only handed to agenix once its
# secrets/<name>.age file is committed, so a host evaluates and boots before
# Max has created it; consumers check `present` and read `path`.
{
  config,
  lib,
  ...
}: let
  file = name: ../../secrets + "/${name}.age";
in {
  options.my.secrets = lib.mkOption {
    default = {};
    type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
      options = {
        owner = lib.mkOption {
          type = lib.types.str;
          default = "root";
        };
        group = lib.mkOption {
          type = lib.types.str;
          default = "root";
        };
        present = lib.mkOption {
          type = lib.types.bool;
          readOnly = true;
          default = builtins.pathExists (file name);
        };
        path = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "/run/agenix/${name}";
        };
      };
    }));
  };

  config.age = {
    # The host key lives on /persist, which is mounted before activation.
    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
    secrets = lib.mapAttrs (name: secret: {
      file = file name;
      inherit (secret) owner group;
    }) (lib.filterAttrs (_: secret: secret.present) config.my.secrets);
  };
}
