{
  config,
  lib,
  pkgs,
  ...
}:
{

  virtualisation = {
    # tpm.enable = true;
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
  };

  # Access to libvirtd
  users.users.shammas = {
    extraGroups = [ "libvirtd" ];
  };

}
