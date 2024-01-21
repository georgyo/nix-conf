{ config, pkgs, ... }:
{
  sops.secrets."mastodon/extraEnv" = {
    sopsFile = ./secrets/extraenv;
    format = "binary";
    restartUnits = [
      "mastodon-sidekiq.service"
      "mastodon-streaming.service"
      "mastodon-web.service"
      "redis-mastodon.service"
    ];
    owner = config.services.mastodon.user;
    group = config.services.mastodon.group;
  };
  services.mastodon = {
    enable = true;
    localDomain = "nycr.social";
    configureNginx = true;
    smtp = {
      fromAddress = "no-reply@nycr.social";
      host = "localhost";
      port = 25;
    };
    streamingProcesses = 3;
    mediaAutoRemove = {
      olderThanDays = 90;
      enable = true;
    };
    smtp.createLocally = false;
    extraConfig = {
      S3_ENABLED = "true";
      S3_BUCKET = "cdn.nycr.social";
      S3_PROTOCOL = "https";
      S3_ALIAS_HOST = "cdn.nycr.social";
      S3_HOSTNAME = "s3.us-east-2.wasabisys.com";
      S3_ENDPOINT = "https://s3.us-east-2.wasabisys.com/";
    };
    extraEnvFiles = [
      config.sops.secrets."mastodon/extraEnv".path
    ];
  };

  services.nginx.virtualHosts."media.nycr.social" = {
    forceSSL = true;
    enableACME = true;
    quic = true;
    locations."/nycr-mastodon/" = {
      proxyPass = "https://s3.us-east-2.wasabisys.com/nycr-mastodon/";
      extraConfig = ''
        proxy_set_header Host 's3.us-east-2.wasabisys.com';
        proxy_set_header Connection "";
        proxy_set_header Authorization "";
        proxy_hide_header Set-Cookie;
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header x-amz-id-2;
        proxy_hide_header x-amz-request-id;
        proxy_hide_header x-amz-meta-server-side-encryption;
        proxy_hide_header x-amz-server-side-encryption;
        proxy_hide_header x-amz-bucket-region;
        proxy_hide_header x-amzn-requestid;
        proxy_ignore_headers Set-Cookie;

        # proxy_cache CACHE;
        proxy_cache_valid 200 48h;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_lock on;

        expires 1y;
        add_header Cache-Control public;
        add_header 'Access-Control-Allow-Origin' '*';
        add_header X-Cache-Status $upstream_cache_status;
      '';
      #  proxy_cache mastodon_media;
      #  proxy_cache_revalidate on;
      #  proxy_buffering on;
      #  proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
      #  proxy_cache_background_update on;
      #  proxy_cache_lock on;
      #  proxy_cache_valid 1d;
      #  proxy_cache_valid 404 1h;
      #  proxy_ignore_headers Cache-Control;
      #  add_header X-Cached $upstream_cache_status;
      #'';
    };
  };
}
