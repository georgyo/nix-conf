{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.smartd = {
    enable = true;
    defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
  };

  services.fwupd.enable = true;

  environment.systemPackages = [ pkgs.smartmontools ];
}
