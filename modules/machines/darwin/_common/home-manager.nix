{
  config,
  inputs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [inputs.determinate.homeManagerModules.default]; # HM integration for Determinate Nix.
    extraSpecialArgs = {
      inherit inputs;
      my = config.my;
    };
    users.${config.my.username} = import ../../../users/mkn;
  };
}
