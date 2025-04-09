{...}: {
  swapDevices = [
    {
      device = "/.swapvol/swapfile";
      # These options are crucial for Btrfs swapfiles
      options = ["discard"];
      # Let NixOS handle the creation and formatting
      # (it will automatically apply the necessary Btrfs-specific settings)
      size = 4096; # 4GiB, matching your disko setup
    }
  ];

  # These settings ensure proper swapfile setup on Btrfs
  boot.kernel.sysctl = {
    # Swappiness - lower values prioritize RAM
    "vm.swappiness" = 10;
  };
}
