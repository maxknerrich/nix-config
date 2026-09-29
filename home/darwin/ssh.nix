# Kronos and its SSH guests over the tailnet, through the Proton Pass agent.
# mosh reads the same configuration, so `mosh zeus` and `mosh kronos` work.
let
  tailnet = host: "${host}.pegasus-sunfish.ts.net";
  guest = host: {
    HostName = tailnet host;
    User = "mkn";
  };
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      kronos = {
        HostName = tailnet "kronos";
        Port = 69;
        User = "mkn";
      };
      zeus = guest "zeus";
      hestia = guest "hestia";
      hades = guest "hades";
    };
  };
}
