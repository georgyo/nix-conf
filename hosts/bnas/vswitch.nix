{
  config,
  lib,
  pkgs,
  ...
}:

let
  openvswitch = pkgs.openvswitch-dpdk.overrideAttrs (
    new: old: {
      buildInputs = old.buildInputs ++ [
        pkgs.libbpf
        pkgs.xdp-tools
      ];
      configureFlags = old.configureFlags ++ [ "--enable-afxdp" ];
    }
  );
in

{
  # virtualisation.vswitch.enable = true;
  virtualisation.vswitch.package = openvswitch;

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
