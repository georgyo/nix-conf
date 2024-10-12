{
  config,
  lib,
  pkgs,
  ...
}:

let
  phpPackage = pkgs.php.buildEnv {
    extensions = (
      { enabled, all }:
      enabled
      ++ (with all; [
        imagick
        opcache
        apcu
        # gnupg
      ])
    );
    extraConfig = ''
      log_errors = On
      display_errors = Off
      upload_max_filesize = 20M
      post_max_size = 21M
    '';
  };
in
{

  containers.nycr6 = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ./common.nix "nycr6") ];

        security.acme = {
          acceptTerms = true;
          defaults.email = "acme@shamm.as";
        };

        environment.systemPackages = with pkgs; [
          htop
          vim
          git
          tcpdump
          graphicsmagick-imagemagick-compat
          phpPackage
          phpPackage.packages.composer
          gnupg
          lua51Packages.lua
        ];

        users.users.wwwrun.home = "/var/lib/wwwrun";

        systemd.services.httpd.path = with pkgs; [
          graphicsmagick-imagemagick-compat
          gnupg
          lua51Packages.lua
        ];

        services = {
          mysql = {
            enable = true;
            package = pkgs.mariadb;
          };
          mysqlBackup = {
            enable = true;
            databases = [ "nycrmw" ];
          };

          cron.enable = true;

          httpd = {
            enable = true;
            enablePHP = true;
            inherit phpPackage;
            extraConfig = ''
              DirectoryIndex index.php index.html
            '';

            extraModules = [ "remoteip" ];

            virtualHosts.wiki = {
              hostName = "wiki.nycresistor.com";
              enableACME = true;
              forceSSL = true;
              documentRoot = "/srv/http/wiki.nycresistor.com";
              locations = {
                "/wiki" = {
                  alias = "/srv/http/wiki.nycresistor.com/w/index.php";
                };
              };
              extraConfig = lib.strings.concatStrings [
                ''
                  <Directory "/srv/http/wiki.nycresistor.com">
                    AllowOverride All
                    DirectoryIndex index.php index.html
                    Options -Indexes +FollowSymLinks
                    Require all granted
                  </Directory>

                  RewriteEngine  on
                  RewriteRule    ^/$ /wiki [R]
                  RemoteIPHeader CF-Connecting-IP
                ''
                (
                  let
                    cloudflare_ips = [
                      "173.245.48.0/20"
                      "103.21.244.0/22"
                      "103.22.200.0/22"
                      "103.31.4.0/22"
                      "141.101.64.0/18"
                      "108.162.192.0/18"
                      "190.93.240.0/20"
                      "188.114.96.0/20"
                      "197.234.240.0/22"
                      "198.41.128.0/17"
                      "162.158.0.0/15"
                      "104.16.0.0/13"
                      "104.24.0.0/14"
                      "172.64.0.0/13"
                      "131.0.72.0/22"
                      "2400:cb00::/32"
                      "2606:4700::/32"
                      "2803:f800::/32"
                      "2405:b500::/32"
                      "2405:8100::/32"
                      "2a06:98c0::/29"
                      "2c0f:f248::/32"
                    ];
                  in
                  lib.concatMapStrings (x: "RemoteIPTrustedProxy " + x + "\n") cloudflare_ips
                )
              ];
            };

            # virtualHosts.pass = {
            #   hostName = "pass.nycresistor.com";
            #   enableACME = true;
            #   forceSSL = true;
            #   documentRoot = "/srv/http/pass.nycresistor.com/webroot";

            #   extraConfig = ''
            #     <Directory "/srv/http/pass.nycresistor.com/webroot">
            #       AllowOverride All
            #       DirectoryIndex index.php index.html
            #       Options -Indexes +FollowSymLinks
            #       Require all granted
            #     </Directory>
            #   '';
            # };
          };
        };
      };
  };
}
