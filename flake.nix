{
  description = "My Nix Conf";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # nur
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    mysecrets = {
      url = "git+ssh://git@github.com/maxknerrich/nix-secrets.git?shallow=1";
      flake = false;
    };
    deploy-rs.url = "github:serokell/deploy-rs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    agenix,
    disko,
    nixos-wsl,
    deploy-rs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Custom packages
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # Reusable nixos modules
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#hostname'
    nixosConfigurations = {
      titan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs;
          vars = import ./hosts/titan/vars.nix;
          mysecrets = inputs.mysecrets;
        };
        # > Our main nixos configuration file <
        modules = [
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager

          ./secrets
          ./hosts/titan
          ./users/mkn
        ];
      };
      fawkes = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          nixos-wsl.nixosModules.default
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager

          ./secrets
          ./hosts/fawkes
          ./users/mkn
        ];
      };
    };
    deploy.nodes = {
      titan = {
        hostname = "titan.local.knerrich.tech";
        profiles.system = {
          user = "root";
          sshUser = "mkn";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.titan;
        };
      };
      fawkes = {
        hostname = "127.0.0.1";
        user = "root";
        sshOpts = ["-p" "69"];
        sshUser = "mkn";
        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.fawkes;
        };
      };
    };
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
