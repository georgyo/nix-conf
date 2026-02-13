{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.jellyfin = {
    enable = true;
    hardwareAcceleration = {
      enable = true;
      device = "/dev/dri/renderD128";
      type = "vaapi";
    };
    transcoding.enableHardwareEncoding = true;
    transcoding.hardwareEncodingCodecs = {
      av1 = true;
      hevc = true;
    };
    transcoding.hardwareDecodingCodecs = {
      vp9 = true;
      vp8 = true;
      vc1 = true;
      mpeg2 = true;
      h264 = true;
      av1 = true;
      hevc = true;
      hevc10bit = true;
    };

  };

  services.traefik.dynamic.files.jellyfin.settings.http = {
    routers.jellyfin = {
      rule = "Host(`fin.seed.v.fu.io`)";
      tls.certResolver = "acme";
      service = "jellyfin";
      entryPoints = [ "webprivate" ];
      middlewares = [
        "limit"
      ];
    };
    services = {
      jellyfin.loadBalancer.servers = [ { url = "http://127.0.0.1:8096"; } ];
    };

  };

  services.tailscale.serve.services.jellyfin = {
    endpoints = {
      "tcp:443" = "http://127.0.0.1:8096";
    };
    advertised = true;
  };

}
