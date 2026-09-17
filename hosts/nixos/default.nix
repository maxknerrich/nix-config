{inputs, ...}: let
  lib = inputs.nixpkgs-stable.lib;
  hostDirectories =
    lib.filterAttrs
    (name: type:
      type
      == "directory"
      && builtins.pathExists (./. + "/${name}/configuration.nix"))
    (builtins.readDir ./.);
  mkSystem = name: _type:
    lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        (./. + "/${name}/configuration.nix")
      ];
    };
in {
  flake.nixosConfigurations = builtins.mapAttrs mkSystem hostDirectories;
}
