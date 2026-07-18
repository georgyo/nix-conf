{
  config,
  lib,
  pkgs,
  ...
}:
let
  presets = import ./presets.nix { inherit lib; };
in
{
  containers.steamvm = {
    autoStart = true;
    macvlans = [ "enp196s0" ];

    config =
      { config, ... }:
      {

        imports = [ ./steamcmd-servers.nix ];

        nixpkgs.pkgs = pkgs;
        system.stateVersion = "26.05"; # Did you read the comment?
        services.dbus.implementation = "broker";

        networking = {
          useNetworkd = true;
          useHostResolvConf = false;
          interfaces.eth0.useDHCP = true;
          interfaces.mv-enp196s0.useDHCP = true;
        };

        programs.nix-ld.enable = lib.mkDefault true;

        services.steamcmd-servers = {
          enable = true;
          openFirewall = true;

          servers.palworld = lib.recursiveUpdate presets.palworld {
            enable = true;
          };
        };

      };
  };
}
