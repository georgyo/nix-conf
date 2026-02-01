{
  lib,
  pkgs,
  config,
  ...
}:
{

  systemd.services.traefik = {
    environment = {
      CF_API_EMAIL = "georgyo@gmail.com";
      CF_DNS_API_TOKEN_FILE = config.age.secrets.CF_API_KEY.path;
      CF_ZONE_API_TOKEN_FILE = config.age.secrets.CF_API_KEY.path;
    };
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      experimental.plugins.demo = {
        moduleName = "github.com/traefik/plugindemo";
        version = "v0.2.2";
      };
      experimental.localPlugins.tailscale-connectivity = {
        moduleName = "github.com/hhftechnology/tailscale-access";
      };

      certificatesResolvers.tailscale.tailscale = { };
      certificatesResolvers.acme.acme = {
        email = "acme@shamm.as";
        storage = "acme.json";
        dnsChallenge.provider = "cloudflare";
      };
      api = {
        dashboard = true;
        insecure = false;
      };
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
          transport.respondingTimeouts.readTimeout = "60m";
          http2.maxConcurrentStreams = "250";
          http3.advertisedPort = "443";
          http.middlewares = [
            "tailscale-ipallowlist"
            # "tailscale-auth"
            # "limit"
          ];
          # tls.certResolver = "acme";
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
          limit.buffering.maxRequestBodyBytes = "4000000000";
          limit.buffering.maxResponseBodyBytes = "4000000000";
          test-auth.basicAuth.users = [
            "admin:$2y$05$IPGM.s6O0uQmWbAByRN1oetJkkfQeWGIdrUlKq8DrLECyE3Wp801S"
          ];
          tailscale-auth.plugin.tailscale-connectivity = {
            testDomain = "bnas.taila8b68.ts.net"; # REQUIRED: Your Tailscale domain
            sessionTimeout = "24h"; # How long verification lasts
            allowLocalhost = true;
          };
        };
        routers = {
          bnasts1 = {
            rule = "Host(`bnas.taila8b68.ts.net`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
            service = "api@internal";
            tls.certResolver = "tailscale";
            entryPoints = [ "webprivate" ];
            middlewares = [ "tailscale-auth" ];
          };
          bnas = {
            rule = "Host(`bnas.fu.io`)";
            service = "api@internal";
            tls.certResolver = "acme";
            entryPoints = [ "webprivate" ];
            middlewares = [ "tailscale-auth" ];
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
          plex = {
            rule = "Host(`plex.fu.io`)";
            tls.certResolver = "acme";
            service = "plex";
            entryPoints = [ "webprivate" ];
            middlewares = [ "limit" ];
          };
          pictures = {
            rule = "Host(`pictures.fu.io`)";
            tls.certResolver = "acme";
            service = "pictures";
            entryPoints = [ "webprivate" ];
            middlewares = [ "limit" ];
          };
          auth = {
            rule = "Host(`auth.fu.io`)";
            tls.certResolver = "acme";
            service = "tailscale-nginx-auth";
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
          plex.loadBalancer.servers = [ { url = "http://127.0.0.1:32400"; } ];
          pictures.loadBalancer.servers = [ { url = "http://192.168.1.186:2283"; } ];
          tailscale-nginx-auth.loadBalancer.servers = [ { url = "http://127.0.0.1:9999"; } ];

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
