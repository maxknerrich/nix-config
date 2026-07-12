{
  lib,
  pkgs,
  ...
}: {
  services.proton-pass-agent = {
    enable = true;
    extraArgs = [
      "--vault-name"
      "Personal"
    ];
  };

  launchd.agents.proton-pass-agent.domain = "gui";

  home = {
    packages = with pkgs;
      [
        # Nix tooling
        alejandra # Formatter used by nix fmt and Zed.
        nixd # Nix language server for Zed.

        # Repo and shell helpers
        ccusage # Coding agent token usage and cost reports.
        codex # OpenAI Codex CLI.
        herdr # Terminal agent multiplexer.
        just # Command runner for this repo.
        mosh # Roaming SSH-like remote shell.
        tree # Quick directory tree viewer.
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        yubikey-manager # Provides the ykman YubiKey CLI.
      ];
    sessionVariables = {
      PI_TELEMETRY = "0"; # Disable Pi telemetry.
    };
  };
}
