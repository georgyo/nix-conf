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
          (makeArr "lidarr")
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

        age.secrets.sabnzbd_settings = {
          file = ./secrets/sabnzbd.ini.age;
          owner = config.services.sabnzbd.user;
          group = config.services.sabnzbd.group;
        };
        services.sabnzbd = {
          enable = true;
          allowConfigWrite = true;
          secretFiles = [
            config.age.secrets.sabnzbd_settings.path
          ];
          settings = {
            misc = {
              host = "0.0.0.0";
              port = 8080;
              host_whitelist = "sabnzbd.seed.v.fu.io";
              complete_dir = "/mnt/data2/incomming";
              permissions = "777";
            };
          };
        };

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

  services.traefik.dynamic.files.seed.settings.http = {
    routers = {
      movies = {
        rule = "Host(`movies.seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "radarr";
        entryPoints = [ "webprivate" ];
      };
      shows = {
        rule = "Host(`shows.seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "sonarr";
        entryPoints = [ "webprivate" ];
      };
      music = {
        rule = "Host(`music.seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "lidarr";
        entryPoints = [ "webprivate" ];
      };
      tracker = {
        rule = "Host(`tracker.seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "prowlarr";
        entryPoints = [ "webprivate" ];
      };
      seed = {
        rule = "Host(`seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "seed";
        entryPoints = [ "webprivate" ];
      };
      autobrr = {
        rule = "Host(`autobrr.seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "autobrr";
        entryPoints = [ "webprivate" ];
      };
      qbittorrent = {
        rule = "Host(`qbittorrent.seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "qbittorrent";
        entryPoints = [ "webprivate" ];
        middlewares = [ "clear-referer" ];
      };
      sabnzbd = {
        rule = "Host(`sabnzbd.seed.v.fu.io`)";
        tls.certResolver = "acme";
        service = "sabnzbd";
        entryPoints = [ "webprivate" ];
      };

    };
    services = {
      sonarr.loadBalancer.servers = [ { url = "http://10.73.105.241:8989"; } ];
      radarr.loadBalancer.servers = [ { url = "http://10.73.105.241:7878"; } ];
      lidarr.loadBalancer.servers = [ { url = "http://10.73.105.241:8686"; } ];
      prowlarr.loadBalancer.servers = [ { url = "http://10.73.105.241:9696"; } ];
      seed.loadBalancer.servers = [ { url = "http://10.73.105.241:80"; } ];
      autobrr.loadBalancer.servers = [ { url = "http://10.73.105.241:7474"; } ];
      qbittorrent.loadBalancer.servers = [ { url = "http://10.73.105.241:7777"; } ];
      sabnzbd.loadBalancer.servers = [ { url = "http://10.73.105.241:8080"; } ];
    };
  };
}
