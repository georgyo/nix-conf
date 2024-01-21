{ config, pkgs, ... }:

let
  phpPackage =
    pkgs.php.buildEnv {
      extensions = ({ enabled, all }: enabled ++ (with all; [
        imagick
        opcache
        apcu
      ]));
      extraConfig = ''
        log_errors = On
        display_errors = Off
      '';
    };

in
{

  containers.nycr6 = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];


    config = { ... }: {
      nixpkgs.pkgs = pkgs;
      imports = [
        (import ./common.nix "nycr6")
      ];

      security.acme = { acceptTerms = true; defaults.email = "acme@shamm.as"; };

      environment.systemPackages = with pkgs; [
        htop
        vim
        git
        tcpdump
        graphicsmagick-imagemagick-compat
        phpPackage
        phpPackage.packages.composer
      ];


      systemd.services.httpd.path = with pkgs; [
        graphicsmagick-imagemagick-compat
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
              "/wiki" = { alias = "/srv/http/wiki.nycresistor.com/w/index.php"; };
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
        };
      };
    };
  };

}
