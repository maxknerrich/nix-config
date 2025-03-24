{vars, ...}: let
  # Generate the dataDisks set
  dataDisks = builtins.listToAttrs (builtins.map (i: {
    name = "d${toString i}";
    value = "/mnt/data${toString i}";
  }) (builtins.genList (x: x + 1) vars.dataDisks));

  contentFiles = builtins.map (
    i: "/mnt/snapraid-content/data${toString i}/snapraid.content"
  ) (builtins.genList (x: x + 1) vars.dataDisks);

  parityFiles = builtins.map (
    i: "/mnt/parity${toString i}/snapraid.parity"
  ) (builtins.genList (x: x + 1) vars.parityDisks);
in {
  services.snapraid = {
    enable = true;
    parityFiles = parityFiles;
    contentFiles = contentFiles;
    dataDisks = dataDisks;
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "downloads/"
      "appdata/"
      "*.!sync"
      "/.snapshots/"
    ];
  };
}
