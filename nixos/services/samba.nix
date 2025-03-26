{...}: {
  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  services.samba = {
    enable = true;
    securityType = "user";
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "titan";
        "netbios name" = "titan";
        "security" = "user";
        "guest ok" = "yes";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "load printers" = "no";
      };
    };
    shares = let
      mkShare = path: {
        path = path;
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "mkn";
        "force group" = "users";
      };
    in {
      storage = mkShare "/mnt/storage";
    };
  };
}
