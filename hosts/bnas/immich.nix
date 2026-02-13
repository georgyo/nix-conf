{
  config,
  lib,
  pkgs,
  ...
}:

{

  containers.pictures = {
    autoStart = true;
    macvlans = [ "enp196s0" ];
    bindMounts = {
      "media" = {
        mountPoint = "/mnt/data";
        hostPath = "/mnt/data/immich";
        isReadOnly = false;
      };
      "/dev/dri" = {
        isReadOnly = false;
      };
    };
    allowedDevices = [
      {
        node = "/dev/dri/renderD128";
        modifier = "rwm";
      }
      {
        node = "/dev/dri/card0";
        modifier = "rwm";
      }
    ];
    config =
      { config, ... }:
      {
        nixpkgs.pkgs = pkgs;
        system.stateVersion = "25.11"; # Did you read the comment?
        services.dbus.implementation = "broker";

        hardware.amdgpu.opencl.enable = true;
        hardware.graphics.enable = true;

        networking = {
          useHostResolvConf = false;
          useNetworkd = true;
          domain = "fu.io";
          useDHCP = lib.mkDefault true;
          interfaces.mv-enp196s0.useDHCP = true;
        };

        users.groups.video.members = [ "immich" ];
        users.groups.render.members = [ "immich" ];

        environment.systemPackages = with pkgs; [
          htop
          vim
          git
          tcpdump
          restic

          ghostty.terminfo # Strictly for TERM happiness
        ];

        services.immich.enable = true;
        services.immich.mediaLocation = "/mnt/data";
        services.immich.host = "0.0.0.0";
        services.immich.openFirewall = true;
      };
  };

  services.traefik.dynamic.files.pictures.settings.http = {
    routers = {
      pictures = {
        rule = "Host(`pictures.fu.io`)";
        tls.certResolver = "acme";
        service = "pictures";
        entryPoints = [ "webprivate" ];
        middlewares = [ "limit" ];
      };
    };
    services = {
      pictures.loadBalancer.servers = [ { url = "http://192.168.1.186:2283"; } ];
    };
  };

}
