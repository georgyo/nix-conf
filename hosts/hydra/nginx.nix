{
  pkgs,
  lib,
  config,
  ...
}:
{

  services.nginx = {
    commonHttpConfig = ''
      log_format  main  '$remote_addr $host $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$request_body"' ;
    '';
    virtualHosts =
      let
        vhosts = builtins.attrNames config.services.nginx.virtualHosts;

        buildVhostExtraParams =
          vhosts:
          builtins.listToAttrs (
            builtins.map (vhost: {
              name = vhost;
              value = {
                quic = true;
                extraConfig = ''
                  access_log  /var/log/nginx/access.log  main;
                '';
              };
            }) vhosts
          );
      in
      buildVhostExtraParams vhosts;
  };
}
