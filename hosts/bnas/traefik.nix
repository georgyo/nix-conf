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

    # static.settings = {
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

    # dynamic = {
    # dir = "/var/lib/traefik/dynamic";
    dynamicConfigOptions = {
      # files.general.settings = {
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
          auth = {
            rule = "Host(`auth.fu.io`)";
            tls.certResolver = "acme";
            service = "tailscale-nginx-auth";
            entryPoints = [ "webprivate" ];
          };
        };
        services = {
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
      # };
    };

  };
}
