{ config, pkgs, ... }:
{
  containers.forge = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ./common.nix "forge") ];

        services.forgejo = {
          enable = true;
          package = pkgs.forgejo;
          database.type = "postgres";
          settings.server = {
            DOMAIN = "forge.scalable.io";
            ROOT_URL = "https://forge.scalable.io";
          };
          settings.service = {
            DISABLE_REGISTRATION = true;
          };
        };

        networking.firewall.allowedUDPPorts = [ 443 ];

        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
            AllowUsers = [ "forgejo" ];
          };
        };

        services.nginx = {
          enable = true;
          package = pkgs.nginxQuic;
          recommendedProxySettings = true;

          virtualHosts = {
            "forge.scalable.io" = {

              serverAliases = [ ];
              forceSSL = true;
              enableACME = true;
              quic = true;
              locations."/".proxyPass = "http://127.0.0.1:3000";
              default = true;
              extraConfig = ''
                client_max_body_size 512M;
              '';
            };
          };
        };

      };
  };
}
