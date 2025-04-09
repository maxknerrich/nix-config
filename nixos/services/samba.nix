{
  config,
  pkgs,
  lib,
  ...
}: let
  # Define the user and group for samba
  hl = {
    user = "share";
    group = "share";
  };
  shares = {
    Sync = {
      path = "/mnt/storage/Sync";
    };
    Media = {
      path = "/mnt/storage/Media";
    };
  };
  commonSettings = {
    "preserve case" = "yes";
    "short preserve case" = "yes";
    "browseable" = "yes";
    "writeable" = "yes";
    "read only" = "no";
    "guest ok" = "no";
    "create mask" = "0644";
    "directory mask" = "0755";
    "valid users" = hl.user;
    "fruit:aapl" = "yes";
    "vfs objects" = "catia fruit streams_xattr";
  };
in {
  users = {
    groups.${hl.group} = {
      gid = 999;
    };
    users.${hl.user} = {
      uid = 999;
      isSystemUser = true;
      group = hl.group;
      createHome = true;
      home = "/var/lib/${hl.user}";
    };
  };

  systemd.tmpfiles.rules =
    [
      "d /var/lib/${hl.user} 0755 ${hl.user} ${hl.group} - -"
    ]
    ++ (map (x: "d ${x.path} 0770 ${hl.user} ${hl.group} - -")
      (lib.attrValues shares));

  system.activationScripts.samba_user_create = ''
    smb_password=$(grep -oP '^FS_PWD=\K.*' ${config.age.secrets.fsPWD.path})
    echo -e "$smb_password\n$smb_password\n" | ${lib.getExe' pkgs.samba "smbpasswd"} -a -s ${hl.user}
  '';

  # make shares visible for windows 10 clients
  services.samba-wsdd = {
    enable = true;
  };
  services.samba = {
    enable = true;
    settings =
      {
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
        # Define shares within settings
      }
      // lib.mapAttrs (name: value: commonSettings // value) shares;
  };
  services.webdav = {
    enable = true;
    user = hl.user;
    group = hl.group;
    environmentFile = config.age.secrets.fsPWD.path;
    settings = {
      address = "0.0.0.0";
      port = 6065;
      directory = "/mnt/storage/Sync";
      debug = true;
      permissions = "CRUD";
      users = [
        {
          username = hl.user;
          password = "{env}FS_PWD";
        }
      ];
    };
  };
}
