# Home Manager for mkn on NixOS hosts. The host's profile is
# home/hosts/linux/<hostname>.nix; Fish is the login shell, as on Fawkes.
{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];

  programs.fish.enable = true;
  users.users.${config.my.username}.shell = pkgs.fish;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-nix";
    extraSpecialArgs = {
      inherit inputs;
      my = config.my;
    };
    # Home Manager follows unstable for Fawkes; NixOS hosts use the stable
    # release, against which its manual pages don't build cleanly.
    sharedModules = [
      {
        home.enableNixpkgsReleaseCheck = false;
        manual.manpages.enable = false;
      }
    ];
    users.${config.my.username} = import ../../home/hosts/linux/${config.networking.hostName}.nix;
  };
}
