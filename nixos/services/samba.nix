{...}: {
  # make shares visible for windows 10 clients
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "MKN";
        "server string" = "titan";
        "security" = "user";
        "invalid users" = ["root"];
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
        "veto files" = "/.snapshots"; # dont show snapshots in samba
      };
    in {
      storage = mkShare "/mnt/storage";
    };
  };
}
