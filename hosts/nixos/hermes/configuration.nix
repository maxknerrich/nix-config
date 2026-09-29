# Hermes: an empty "strong container" for assistant agents, added later
# through Nix. No SSH, Tailscale or Home Manager; rebuilt, not administered.
# Its serial console is logged by `microvm@hermes` on Kronos.
{
  imports = [../../../modules/nixos/guest.nix];

  networking.hostName = "hermes";

  my.guest = {
    ssh = false;
    tailscale = false;
  };
}
