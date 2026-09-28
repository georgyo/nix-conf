{ config, pkgs, ... }:
{

  services.nginx.virtualHosts."pds.shamm.as" = {
    enableACME = true;
    quic = true;
    http3 = true;
    forceSSL = true;
    extraConfig = ''
      client_max_body_size 10G;
    '';
    locations."/" = {
      recommendedProxySettings = true;
      proxyPass = "http://192.168.55.21:3000";
    };
    locations."/xrpc/" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://192.168.55.21:3000";
      extraConfig = ''
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_buffering off;
        proxy_request_buffering off;
      '';
    };
  };

  containers.tranquil-pds = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { config, ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [
          (import ../common.nix "tranquil-pds")
          pkgs.flakeInputs.sops-nix.nixosModules.sops
        ];

        networking.firewall.allowedUDPPorts = [ ];
        networking.firewall.allowedTCPPorts = [ 3000 ];
        sops = {
          age = {
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };
          # JWT_SECRET, DPOP_SECRET and MASTER_KEY
          secrets."tranquil-pds.env" = {
            sopsFile = ./secrets/tranquil-pds.env;
            format = "dotenv";
            restartUnits = [
              "tranquil-pds.service"
            ];
          };
        };

        services.tranquil-pds = {
          enable = true;
          database.createLocally = true;
          environmentFiles = [ config.sops.secrets."tranquil-pds.env".path ];
          settings = {
            server = {
              hostname = "pds.shamm.as";
              host = "0.0.0.0";
              port = 3000;
              contact_email = "pds@shamm.as";
              enable_pds_hosted_did_web = true;
              user_handle_domains = [ "shamm.as" ];
            };
            email = {
              from_address = "pds@shamm.as";
              smarthost = {
                host = "192.168.55.1";
                port = 25;
                tls = "none";
              };
            };
          };
        };
      };
  };
}
