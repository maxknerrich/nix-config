{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      # Nix tooling
      alejandra # Formatter used by nix fmt and Zed.
      nixd # Nix language server for Zed.

      # Repo and shell helpers
      just # Command runner for this repo.
      tree # Quick directory tree viewer.
    ];
    sessionVariables = {
      PI_CODING_AGENT_DIR = "$XDG_CONFIG_HOME/pi/agent"; # Keep Pi state under XDG config.
      PI_TELEMETRY = "0"; # Disable Pi telemetry.
    };
  };
}
