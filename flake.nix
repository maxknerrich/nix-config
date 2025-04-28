{
  description = "My Nix Conf";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    # Also see the 'stable-packages' overlay at 'overlays/default.nix'.

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # nur
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

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
    impermanence,
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
          impermanence.nixosModules.impermanence

          ./core

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

          ./core

          ./secrets
          ./hosts/fawkes
          ./users/mkn
        ];
      };
      blackjack = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager

          ./core

          ./secrets
          ./hosts/blackjack
          ./users/mkn
        ];
      };
    };
    deploy.nodes = {
      titan = {
        hostname = "titan.local.knerrich.tech";
        sshOpts = ["-p" "69"];
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
      blackjack = {
        hostname = "192.168.2.40";
        user = "root";
        sshOpts = ["-p" "69"];
        sshUser = "mkn";
        interactiveSudo = true;
        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.blackjack;
        };
      };
    };
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
