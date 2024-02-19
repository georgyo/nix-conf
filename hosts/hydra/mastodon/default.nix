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
    # We no longer use this site, but we need to keep around as even though it
    # has not been used in about a year as of Feb 2024, there are still several
    # hundred requests per day to it.
    forceSSL = true;
    enableACME = true;
    quic = true;
    locations."/" = {
      extraConfig = ''
        rewrite ^/nycr-mastodon/(.*)$ https://cdn.nycr.social/$1 last;
        return  302 https://cdn.nycr.social$request_uri;
      '';
    };
  };
}
