{
  config,
  lib,
  pkgs,
  ...
}:

{
  # virtualisation.vswitch.enable = true;

  # networking.macvlans.vs-out = {
  #   mode = "bridge";
  #   interface = "enp196s0";
  # };

  networking.vswitches.vs0 = {
    interfaces = {
      vs-out = { };
      lo1 = {
        type = "internal";
      };
    };
  };

}
