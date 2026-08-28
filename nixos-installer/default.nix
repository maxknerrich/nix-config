{inputs, ...}: {
  flake.nixosConfigurations.installer = inputs.nixpkgs-stable.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules = [
      (inputs.nixpkgs-stable + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
      ./configuration.nix
    ];
  };
}
