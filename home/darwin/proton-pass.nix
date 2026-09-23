{
  config,
  pkgs,
  ...
}: {
  # Proton Pass Desktop owns the SSH agent; the CLI remains for `just` workflows.
  home = {
    packages = [pkgs.proton-pass-cli];
    sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.ssh/proton-pass-ssh-agent.sock";
  };
}
