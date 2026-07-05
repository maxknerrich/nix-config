{
  description = "Max's Nix system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin"];
      imports = [
        ./modules/machines/darwin
        ./modules/machines/nixos
      ];

      perSystem = {pkgs, ...}: {
        # Keep nix fmt lightweight without a separate treefmt module.
        formatter = pkgs.writeShellApplication {
          name = "nix-config-fmt";
          runtimeInputs = [pkgs.alejandra];
          text = ''
            if [ "$#" -eq 0 ]; then
              set -- .
            fi
            alejandra "$@"
          '';
        };
      };
    };
}
