{inputs, ...}: let
  entries = builtins.readDir ./.;
  # Each host is a directory with a configuration.nix.
  names = builtins.filter (name: entries.${name} == "directory" && name != "_common" && builtins.pathExists (./. + "/${name}/configuration.nix")) (builtins.attrNames entries);
  mkDarwin = name: {
    inherit name;
    value = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {inherit inputs;};
      modules = [
        inputs.determinate.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.home-manager.darwinModules.home-manager
        ./${name}/configuration.nix
      ];
    };
  };
in {
  flake.darwinConfigurations = builtins.listToAttrs (map mkDarwin names);
}
