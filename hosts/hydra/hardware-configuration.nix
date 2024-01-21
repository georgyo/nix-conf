# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  # Moved this import to flake.nix
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "ahci" "sd_mod" ];
  boot.kernelModules = [ ];
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernelParams =
    [ "console=ttyS0,19200n8" "systemd.unified_cgroup_hierarchy=true" "mitigations=off" ];
  boot.loader.grub.device = "/dev/disk/by-path/pci-0000:00:02.0-scsi-0:0:0:0";
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit 0 --word=8 --parity=no --stop=1;
    terminal_input serial;
    terminal_output serial;
  '';
  boot.loader.timeout = 10;
  boot.extraModulePackages = [ ];
  boot.swraid.enable = false;

  fileSystems = let btrfsOptions = [ "relatime" "ssd" "noacl" "space_cache" "autodefrag" ]; in
    {
      "/" = {
        device = ''UUID=fc4d02c3-5e58-4430-91a5-2a403a4b915d'';
        fsType = "ext4";
      };
      "/var/lib/ipfs" = {
        device = ''UUID=3e019d8b-bfa3-42e6-aa73-0f783694279a'';
        fsType = "btrfs";
        options = btrfsOptions ++ [ "subvol=services/ipfs" ];
      };
      "/var/lib/postgresql" = {
        device = ''UUID=3e019d8b-bfa3-42e6-aa73-0f783694279a'';
        fsType = "btrfs";
        options = btrfsOptions ++ [ "subvol=services/postgresql" ];
      };
      "/var/lib/mastodon" = {
        device = ''UUID=3e019d8b-bfa3-42e6-aa73-0f783694279a'';
        fsType = "btrfs";
        options = btrfsOptions ++ [ "subvol=services/mastodon" ];
      };
      "/home" = {
        device = ''UUID=3e019d8b-bfa3-42e6-aa73-0f783694279a'';
        fsType = "btrfs";
        options = btrfsOptions ++ [ "subvol=home" ];
      };
      "/var/lib/nixos-containers" = {
        device = ''UUID=3e019d8b-bfa3-42e6-aa73-0f783694279a'';
        fsType = "btrfs";
        options = btrfsOptions ++ [ "subvol=nixos-containers" ];
      };
      "/var/lib/machines" = {
        device = ''UUID=3e019d8b-bfa3-42e6-aa73-0f783694279a'';
        fsType = "btrfs";
        options = btrfsOptions ++ [ "subvol=machines" ];
      };
    };

  zramSwap = {
    enable = true;
    writebackDevice = ''/dev/disk/by-uuid/1d530e93-10c0-47ec-94b3-0d853a3af291'';
  };
  #swapDevices = [{ device = "/dev/sdb"; }];

  nix.settings.max-jobs = lib.mkDefault 2;
}
