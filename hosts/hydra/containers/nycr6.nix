{
  config,
  lib,
  pkgs,
  ...
}:

let

  luasandbox = pkgs.php.buildPecl rec {
    pname = "luasandbox";
    version = "4.1.2";
    src = pkgs.fetchFromGitHub {
      owner = "wikimedia";
      repo = "mediawiki-php-luasandbox";
      tag = version;
      hash = "sha256-HWObytoHBvxF9+QC62yJfi6MuHOOXFbSNkhuz5zWPCY=";
    };
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.lua51Packages.lua ];
    meta = with lib; {
      description = "extension for PHP 7 and PHP 8 to allow safely running untrusted Lua 5.1 code from within PHP";
      license = licenses.mit;
      homepage = "https://www.mediawiki.org/wiki/LuaSandbox";
      maintainers = with lib.maintainers; [ georgyo ];
    };
  };

  phpPackage = pkgs.php.buildEnv {
    extensions = (
      { enabled, all }:
      enabled
      ++ (with all; [
        imagick
        opcache
        apcu
        wikidiff2
        luasandbox
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

  myConfig = config.containers.nycr6.config;
in
{

  containers.nycr6 = {
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
          (import ./common.nix "nycr6")
          (import ./modules/cloudflare_remoteip.nix "wiki")
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
          gnupg
          lua51Packages.lua
          python3Packages.pygments
        ];

        networking.firewall.allowedUDPPorts = [ 443 ];

        systemd.services.httpd.path = with pkgs; [
          graphicsmagick-imagemagick-compat
          gnupg
          lua51Packages.lua
          python3Packages.pygments
        ];

        # This user is no longer used, but kept around because of file ownership.
        users.groups.wwwrun = { };
        users.users.wwwrun = {
          home = "/var/lib/wwwrun";
          isSystemUser = true;
          group = "wwwrun";
        };

        services = {
          mysql = {
            enable = true;
            package = pkgs.mariadb;
          };
          mysqlBackup = {
            enable = true;
            databases = [ "nycrmw" ];
          };

          phpfpm = {
            inherit phpPackage;
            pools.web = {
              user = "nginx";
              settings = {
                pm = "dynamic";
                "listen.owner" = myConfig.services.nginx.user;
                "pm.max_children" = 5;
                "pm.start_servers" = 2;
                "pm.min_spare_servers" = 1;
                "pm.max_spare_servers" = 3;
                "pm.max_requests" = 500;
              };
            };
          };

          nginx = {
            enable = true;
            package = pkgs.nginxQuic;
            virtualHosts."wiki.nycresistor.com" = {
              root = "/srv/http/wiki.nycresistor.com";
              enableACME = true;
              addSSL = true;
              quic = true;
              default = true;
              extraConfig = ''
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                include ${pkgs.nginx}/conf/fastcgi.conf;
                index = "index.php";
              '';
              locations = lib.fix (self: {
                # Most of this matches the config from here:
                # https://www.mediawiki.org/wiki/Manual:Short_URL/Nginx
                "~ ^/w/(mw-config/)?(index|load|api|thumb|opensearch_desc|rest|img_auth)\\.php$" = {
                  fastcgiParams.SCRIPT_FILENAME = "$document_root$fastcgi_script_name";
                  extraConfig = ''
                    fastcgi_pass unix:${myConfig.services.phpfpm.pools.web.socket};

                  '';
                };
                "/w/images".extraConfig = ''
                  # Separate location for images/ so .php execution won't apply
                  # as required starting from v1.40
                  add_header X-Content-Type-Options "nosniff";
                  # Serve uploaded HTML as plaintext, don't execute SHTML
                  types { text/plain html htm shtml phtml; }
                '';
                "~ ^/w/resources/(assets|lib|src)".extraConfig = ''
                  try_files $uri =404;
                  add_header Cache-Control "public";
                  expires 7d;
                '';

                "= /favicon.ico".extraConfig = ''
                  alias /w/images/6/64/Favicon.ico;
                  add_header Cache-Control "public";
                  expires 7d;
                '';
                "/w/rest.php/".tryFiles = "$uri $uri/ /w/rest.php?$query_string";

                "~ ^/w/(skins|extensions)/.+\\.(css|js|gif|jpg|jpeg|png|svg|wasm|ttf|woff|woff2)$".extraConfig = ''
                  try_files $uri =404;
                  add_header Cache-Control "public";
                  expires 7d;
                '';
                "/wiki/".extraConfig = ''
                  rewrite ^/wiki/(?<pagename>.*)$ /w/index.php;
                '';
                "= /".return = "301 /wiki/Main_Page";
                "= /robots.txt" = { };

                # However we moved images, skins, and load.php to a different place to help with caching.
                "/images" = self."/w/images";
                "/skins".tryFiles = "$uri =404";
                "/load.php" = {
                  fastcgiParams.SCRIPT_FILENAME = "$document_root$fastcgi_script_name";
                  extraConfig = ''
                    fastcgi_pass unix:${myConfig.services.phpfpm.pools.web.socket};
                  '';
                };

                # Must be the last rule
                "/".return = "404";
              });

            };
          };
        };
      };
  };
}
