{
  lib,
  pkgs,
  config,
  ...
}:
{

  systemd.services.traefik.environment = {
    CF_API_EMAIL = "georgyo@gmail.com";
    CF_DNS_API_TOKEN_FILE = config.age.secrets.CF_API_KEY.path;
    CF_ZONE_API_TOKEN_FILE = config.age.secrets.CF_API_KEY.path;
  };
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      certificatesResolvers.tailscale.tailscale = { };
      certificatesResolvers.acme.acme = {
        email = "acme@shamm.as";
        storage = "acme.json";
        dnsChallenge.provider = "cloudflare";
      };
      api = { };
      entryPoints = {
        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "webprivate";
            scheme = "https";
            permanent = true;
          };
        };
        webprivate = {
          address = ":443";
          reusePort = true;
          http2.maxConcurrentStreams = "250";
          http3.advertisedPort = "443";
          http.middlewares = [
            "tailscale-ipallowlist"
          ];
        };
      };
    };

    dynamicConfigOptions = {
      http = {
        middlewares = {
          tailscale-ipallowlist.ipAllowList.sourceRange = [ "100.64.0.0/10" ];
          clear-referer.headers.customRequestHeaders = {
            "Referer" = "";
          };
        };
        routers = {
          bnasts1 = {
            rule = "Host(`bnas.taila8b68.ts.net`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
            service = "api@internal";
            tls.certResolver = "tailscale";
            entryPoints = [ "webprivate" ];
          };
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
          plex = {
            rule = "Host(`plex.fu.io`)";
            tls.certResolver = "acme";
            service = "plex";
            entryPoints = [ "webprivate" ];
          };
        };
        services = {
          sonarr.loadBalancer.servers = [ { url = "http://10.73.105.241:8989"; } ];
          radarr.loadBalancer.servers = [ { url = "http://10.73.105.241:7878"; } ];
          prowlarr.loadBalancer.servers = [ { url = "http://10.73.105.241:9696"; } ];
          seed.loadBalancer.servers = [ { url = "http://10.73.105.241:80"; } ];
          autobrr.loadBalancer.servers = [ { url = "http://10.73.105.241:7474"; } ];
          qbittorrent.loadBalancer.servers = [ { url = "http://10.73.105.241:7777"; } ];
          sabnzbd.loadBalancer.servers = [ { url = "http://10.73.105.241:8080"; } ];
          plex.loadBalancer.servers = [ { url = "http://127.0.0.1:32400"; } ];

          service1 = {
            loadBalancer = {
              servers = [
                {
                  url = "http://localhost:8080";
                }
              ];
            };
          };
        };
      };

    };

  };
}
