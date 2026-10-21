{ config, pkgs, ... }:
let
  phpPackage = pkgs.php.buildEnv {
    extensions = (
      { enabled, all }:
      enabled
      ++ (with all; [
        imagick
        apcu
        redis
      ])
    );
    extraConfig = ''
      log_errors = On
      display_errors = Off
      ; Mitigation for CVE-2026-109618 / CVE-2026-109619
      session.upload_progress.enabled = Off
    '';
  };
in
{

  containers.tanya = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [
          (import ./common.nix "tanya")
          (import ./modules/cloudflare_remoteip.nix "wordpress")
        ];

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
              # Mitigation for CVE-2026-109618 / CVE-2026-109619: lock upload
              # progress off and reject multipart bodies before PHP parses them.
              # Note: this blocks WordPress media uploads until PHP is patched.
              extraConfig = ''
                php_admin_flag session.upload_progress.enabled off
                <If "req('Content-Type') =~ /multipart/i">
                  Require all denied
                </If>
              '';
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
