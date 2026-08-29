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
        inputs.agenix.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.impermanence.nixosModules.impermanence
        (./. + "/${name}/configuration.nix")
      ];
    };
in {
  flake.nixosConfigurations = builtins.mapAttrs mkSystem hostDirectories;
}
