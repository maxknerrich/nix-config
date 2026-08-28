{
  description = "Headless NixOS installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {nixpkgs, ...}: {
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
        ./configuration.nix
      ];
    };
  };
}
