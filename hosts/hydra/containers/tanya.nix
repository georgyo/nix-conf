{ config, pkgs, ... }:
let
  phpPackage = pkgs.php.buildEnv {
    extensions = (
      { enabled, all }:
      enabled
      ++ (with all; [
        imagick
        opcache
        apcu
        redis
      ])
    );
    extraConfig = ''
      log_errors = On
      display_errors = Off
    '';
  };
in
{

  containers.tanya = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [
          (import ./common.nix "tanya")
          (import ./modules/cloudflare_remoteip.nix "wordpress")
        ];

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
        ];

        systemd.services.httpd.path = with pkgs; [ graphicsmagick-imagemagick-compat ];

        networking.firewall = {
          allowedTCPPorts = [
            80
            443
          ];
        };

        services = {
          mysql = {
            enable = true;
            package = pkgs.mariadb;
          };
          mysqlBackup = {
            enable = true;
            databases = [ "wordpress" ];
          };
          redis.servers."".enable = true;

          cron = {
            enable = true;
            systemCronJobs = [ "* * * * * wwwrun php /srv/http/wp-cron.php" ];
          };

          httpd = {
            enable = true;
            enablePHP = true;
            inherit phpPackage;
            virtualHosts.wordpress = {
              hostName = "nowossjolka.com";
              enableACME = true;
              forceSSL = true;
              documentRoot = "/srv/http/";
            };
            extraConfig = ''
                <Directory "/srv/http">

                # standard wordpress .htaccess contents
                <IfModule mod_rewrite.c>
                  RewriteEngine On
                  RewriteBase /
                  RewriteRule ^index\.php$ - [L]
                  RewriteCond %{REQUEST_FILENAME} !-f
                  RewriteCond %{REQUEST_FILENAME} !-d
                  RewriteRule . /index.php [L]
                </IfModule>

                DirectoryIndex index.php
                Require all granted
                Options +FollowSymLinks -Indexes

                </Directory>

              # https://wordpress.org/support/article/hardening-wordpress/#securing-wp-config-php
              <Files wp-config.php>
                Require all denied
              </Files>


            '';
          };
        };
      };
  };
}
