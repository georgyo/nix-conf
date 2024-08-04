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

              extraConfig = ''
                <Directory "/srv/http/wiki.nycresistor.com">
                  AllowOverride All
                  DirectoryIndex index.php index.html
                  Options -Indexes +FollowSymLinks
                  Require all granted
                </Directory>

                RewriteEngine  on
                RewriteRule    ^/$ /wiki [R]

              '';
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
