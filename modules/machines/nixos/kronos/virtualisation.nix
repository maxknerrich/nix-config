{pkgs, ...}: {
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  # Guest definitions and their restricted NAT network remain declarative follow-up work.
  programs.virt-manager.enable = false;
}
