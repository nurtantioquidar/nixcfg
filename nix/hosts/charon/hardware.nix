{ modulesPath, ... }:

{
  # Tencent Cloud VPS (KVM, virtio disk and NIC).
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # The firmware mode is unverified, so the GPT layout in disko.nix carries
  # both a BIOS boot partition and an ESP. disko sets the GRUB device from
  # the EF02 partition; the removable EFI path needs no NVRAM entry.
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en* eth*";
    networkConfig.DHCP = "yes";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
