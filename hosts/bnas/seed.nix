{
  config,
  pkgs,
  lib,
  ...
}:

let
  makeArr = type: {
    services.${type} = {
      enable = true;
      settings = {
        postgres = {
          host = "/run/postgresql";
          maindb = "${type}";
          logdb = "${type}_logs";
          user = "${type}";
          port = 5432;
        };
      };
    };
    # // lib.optionalAttrs (type == "radarr") { package = pkgs.callPackage ./packages/radarr { }; };

    services.postgresql = {
      ensureUsers = [
        {
          name = type;
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [
        "${type}"
        "${type}_logs"
      ];
    };
  };

in
{

  systemd.services."container@seed".bindsTo = [ "wg-netns@seed.service" ];
  systemd.services."container@seed".after = [ "wg-netns@seed.service" ];
  containers.seed = {
    autoStart = true;
    networkNamespace = "/run/netns/seed";
    bindMounts = {
      "media" = {
        mountPoint = "/mnt/data2";
        hostPath = "/mnt/data/media";
        isReadOnly = false;
      };
    };
    config =
      { config, ... }:
      {
        nixpkgs.pkgs = pkgs;
        system.stateVersion = "25.11"; # Did you read the comment?

        imports = [
          (makeArr "sonarr")
          (makeArr "radarr")
          (makeArr "prowlarr")
        ];

        networking = {
          useHostResolvConf = false;
          useNetworkd = true;
          domain = "fu.io";
          nameservers = [
            "1.1.1.1"
            "8.8.8.8"
          ];

          # Firewall is handled outside this namespace.
          firewall.enable = false;

        };

        environment.systemPackages = with pkgs; [
          htop
          vim
          git
          tcpdump
          restic
          unrar

          ghostty.terminfo # Strictly for TERM happiness
        ];
        services.dbus.implementation = "broker";

        services.sshd.enable = true;
        services.qbittorrent = {
          enable = true;
          webuiPort = 7777;
        };
        services.sabnzbd.enable = true;
        services.flaresolverr.enable = true;
        services.postgresql = {
          enable = true;
          enableJIT = true;
        };

        age.secrets.autobrr-session.file = ./secrets/autobrr-session.age;
        services.autobrr = {
          enable = true;
          secretFile = config.age.secrets.autobrr-session.path;
          settings = {
            host = "0.0.0.0";
            port = 7474;
          };
        };

        services.nginx = {
          enable = true;
          virtualHosts = {
            "seed.v.fu.io" = {
              serverAliases = [ "seed.fu.io" ];
              root = ./seed-webroot;
            };
          };
        };
      };
  };
}
