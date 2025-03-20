{
  inputs,
  pkgs,
  unstablePkgs,
  ...
}: let
  inherit (inputs) nixpkgs nixpkgs-unstable;
in {
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    ## stable
    btop
    coreutils
    drill
    fastfetch
    fd
    figurine
    gh
    git-crypt
    iperf3
    jq
    mc
    ripgrep
    tree
    unzip
    watch
    wget
    zoxide
    inputs.agenix.packages."${system}".default
  ];
}
