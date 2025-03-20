{
  config,
  lib,
  ...
}: {
  services.snapraid = {
    enable = true;
    parityFiles = ["/mnt/parity1/snapraid.parity"];
    contentFiles = [
      "/mnt/disk1/snapraid.content"
      "/mnt/disk2/snapraid.content"
    ];
    dataDisks = {
      d1 = "/mnt/disk1";
      d2 = "/mnt/disk2";
    };
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "downloads/"
      "appdata/"
      "*.!sync"
    ];
  };
  systemd = {
    timers = {
      snapraid-sync = {
        wantedBy = ["timers.target"];
        timerConfig = {
          # Run daily at 2:00 AM
          OnCalendar = "18:00:00";
          # If system was off when timer should have run, run it soon after boot
          Persistent = true;
        };
      };

      snapraid-scrub = {
        wantedBy = ["timers.target"];
        timerConfig = {
          # Run weekly on Sundays at 23:00
          OnCalendar = "Sun 23:00:00";
          Persistent = true;
        };
      };
    };
    services = lib.attrsets.optionalAttrs (config.services.snapraid.enable) {
      snapraid-sync = {
        onFailure = lib.lists.optionals (config ? tg-notify && config.tg-notify.enable) [
          "tg-notify@%i.service"
        ];
        serviceConfig = {
          RestrictNamespaces = lib.mkForce false;
          RestrictAddressFamilies = lib.mkForce "";
        };
      };
      snapraid-scrub = {
        onFailure = lib.lists.optionals (config ? tg-notify && config.tg-notify.enable) [
          "tg-notify@%i.service"
        ];
        serviceConfig = {
          RestrictNamespaces = lib.mkForce false;
          RestrictAddressFamilies = lib.mkForce "";
        };
      };
    };
  };
}
