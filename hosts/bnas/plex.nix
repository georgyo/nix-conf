{ ... }:
{
  services.plex = {
    enable = true;
    # group = "media";
  };

  # services.traefik.dynamic.files.plex.settings.http = {
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      plex = {
        rule = "Host(`plex.fu.io`)";
        tls.certResolver = "acme";
        service = "plex";
        entryPoints = [ "webprivate" ];
        middlewares = [ "limit" ];
      };
    };
    services = {
      plex.loadBalancer.servers = [ { url = "http://127.0.0.1:32400"; } ];
    };
  };

}
