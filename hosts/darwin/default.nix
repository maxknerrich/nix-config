{inputs, ...}: let
  entries = builtins.readDir ./.;
  # Each host is a directory with a configuration.nix.
  names = builtins.filter (name: entries.${name} == "directory" && builtins.pathExists (./. + "/${name}/configuration.nix")) (builtins.attrNames entries);
  mkDarwin = name: {
    inherit name;
    value = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {inherit inputs;};
      modules = [
        ./${name}/configuration.nix
      ];
    };
  };
in {
  flake.darwinConfigurations = builtins.listToAttrs (map mkDarwin names);
}
