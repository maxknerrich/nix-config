# Hades: backup and monitoring. Kopia server for Fawkes's home repository,
# the Proton Drive mirror, the offsite job, Gatus and ntfy.
{
  imports = [
    ../../../modules/nixos/guest.nix
    ../../../modules/nixos/home.nix
    ../../../modules/nixos/notify.nix
    ./backup.nix
    ./monitoring.nix
  ];

  networking.hostName = "hades";

  my.guest.certificate = "home.knerrich.tech";

  microvm.shares =
    # Only the three guest-state snapshot series, never the snapshot tree:
    # @persist's snapshots hold Kronos's host key, its agenix identity.
    map (series: {
      tag = "snap-${series}";
      source = "/srv/snapshots/${series}";
      mountPoint = "/snapshots/${series}";
      proto = "virtiofs";
      readOnly = true;
    }) [
      "hestia-state"
      "hades-state"
      "hermes-state"
    ]
    ++ [
      {
        tag = "kopia-home";
        source = "/srv/storage/kopia-home";
        mountPoint = "/srv/kopia-home";
        proto = "virtiofs";
      }
      {
        tag = "proton";
        source = "/srv/storage/proton";
        mountPoint = "/srv/proton";
        proto = "virtiofs";
      }
    ];
}
