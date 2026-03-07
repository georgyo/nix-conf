{
  config,
  lib,
  pkgs,
  ...
}:

{

  services.nginx.virtualHosts."auth.fu.io" = {
    enableACME = true;
    quic = true;
    http3 = true;
    forceSSL = true;
    serverAliases = [
      "auth.fu.io"
    ];
    locations."/" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://192.168.55.18:1411";
    };
  };

  containers.pocketid = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { config, ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ../common.nix "pocketid")
          pkgs.flakeInputs.sops-nix.nixosModules.sops
        ];

        networking.firewall.allowedUDPPorts = [ ];
        networking.firewall.allowedTCPPorts = [ 1411 ];
        sops = {
          age = {
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };
          defaultSopsFile = ./secrets/secrets.yaml;
          secrets."pocketid.env" = {
    sopsFile = ./secrets/pocketid.env;
    format = "dotenv";
    restartUnits = [
      "pocket-id.service"
    ];
  };
        };

        services.pocket-id = {
          enable = true;
          settings = {
            TRUST_PROXY = true;
            APP_URL = "https://auth.fu.io";
            ANALYTICS_DISABLED = true;
          };
          environmentFile = 
        config.sops.secrets."pocketid.env".path;

        };

      };
  };
}
