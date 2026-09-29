# The hardware Kronos gives each guest. Kronos's modules and the shared guest
# base both read this table, so a guest's address, size and storage are defined
# once. `id` picks the routed segment 10.100.<id>.0/24 (Kronos .1, guest .2).
# `tailnet` is the guest's Tailscale IPv4, filled in after enrolment; private
# DNS names only resolve once it is known.
{
  hermes = {
    id = 10;
    mem = 1024;
    vcpu = 2;
    tailnet = null;
    state = "/srv/guests/hermes/state";
  };

  zeus = {
    id = 20;
    mem = 6144;
    vcpu = 4;
    tailnet = "100.75.144.84";
    # Block volumes under Kronos's @vms subvolume; `scratch` is a nested
    # subvolume, so the store overlay stays out of every snapshot.
    volumes = {
      home = {
        image = "home.img";
        size = 81920;
        mountPoint = "/persist";
      };
      store = {
        image = "scratch/store.img";
        size = 61440;
        mountPoint = "/nix/.rw-store";
      };
    };
  };

  hestia = {
    id = 30;
    mem = 3072;
    vcpu = 4;
    tailnet = "100.89.246.95";
    state = "/srv/guests/hestia/state";
  };

  hades = {
    id = 40;
    mem = 1024;
    vcpu = 2;
    tailnet = "100.85.54.23";
    state = "/srv/guests/hades/state";
  };
}
