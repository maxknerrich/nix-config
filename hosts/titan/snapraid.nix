{...}: {
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
}
