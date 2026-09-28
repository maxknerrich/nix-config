# Daily btrbk snapshots. rpool subvolumes keep two snapshots on the SSDs (the
# incremental parent plus one retry) and are sent to dtank for long retention;
# dtank subvolumes are snapshotted in place. Every series has its own directory
# under /srv/snapshots so the three guest-state series can be shared to Hades.
_: let
  longRetention = "7d 4w 6m";
  series = [
    "vms"
    "persist"
    "hestia-state"
    "hades-state"
    "hermes-state"
    "proton"
    "kopia-home"
  ];
in {
  services.btrbk.instances.btrbk = {
    onCalendar = "*-*-* 01:30:00";
    settings = {
      # Hades's offsite job reads the snapshot time from the name.
      timestamp_format = "long-iso";
      snapshot_preserve_min = "latest";
      target_preserve_min = "no";

      volume."/mnt/rpool" = {
        snapshot_dir = "btrbk";
        snapshot_preserve = "2d";
        target_preserve = longRetention;
        subvolume = {
          "@vms".target = "/srv/snapshots/vms";
          "@persist".target = "/srv/snapshots/persist";
          "@hestia-state".target = "/srv/snapshots/hestia-state";
        };
      };

      volume."/mnt/dtank" = {
        snapshot_preserve = longRetention;
        subvolume = {
          "@hades-state".snapshot_dir = "@snapshots/hades-state";
          "@hermes-state".snapshot_dir = "@snapshots/hermes-state";
          "@proton".snapshot_dir = "@snapshots/proton";
          # Protects the repository from a deleting client; fawkes is the origin.
          "@kopia-home" = {
            snapshot_dir = "@snapshots/kopia-home";
            snapshot_preserve = "7d";
          };
        };
      };
    };
  };

  my.notify.units = ["btrbk-btrbk"];

  systemd.tmpfiles.rules =
    ["d /mnt/rpool/btrbk 0700 root root"]
    ++ map (name: "d /srv/snapshots/${name} 0700 root root") series;
}
