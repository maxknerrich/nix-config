{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    alejandra
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    nixd
    ccusage
    codex
    gh
    just
  ];

  programs.fish.interactiveShellInit = ''
    # Vite Plus manages Node outside Nix.
    if test -f "$HOME/.vite-plus/env.fish"
      source "$HOME/.vite-plus/env.fish"
    end
  '';
}
