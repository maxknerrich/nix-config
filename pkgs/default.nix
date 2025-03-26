{pkgs, ...}: {
  cockpit-benchmark = pkgs.callPackage ./cockpit/benchmark {};
  cockpit-file-sharing = pkgs.callPackage ./cockpit/file-sharing {};
  cockpit-files = pkgs.callPackage ./cockpit/files {};
  cockpit-machines = pkgs.callPackage ./cockpit/machines {};
  cockpit-sensors = pkgs.callPackage ./cockpit/sensors {};

  snapraid-btrfs = pkgs.callPackage ./snapraid-btrfs {};
}
