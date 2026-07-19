{ config, pkgs, ... }:
{

  services.nginx.virtualHosts."niks3.fu.io" = {
    enableACME = true;
    quic = true;
    http3 = true;
    forceSSL = true;
    serverAliases = [
      "niks3.fu.io"
    ];
    locations."/" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://192.168.55.20:5751";
    };
  };

  containers.niks3 = {
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
          (import ../common.nix "niks3")
          pkgs.flakeInputs.niks3.nixosModules.niks3
          pkgs.flakeInputs.sops-nix.nixosModules.sops

        ];
        sops = {
          age = {
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };
          defaultSopsFile = ./secrets/secrets.yaml;
          secrets.niks3-api-token.owner = "niks3";
          secrets.niks3-signing-key.owner = "niks3";
          secrets.niks3-s3-access-key.owner = "niks3";
          secrets.niks3-s3-secret-key.owner = "niks3";
        };
        networking.firewall.allowedUDPPorts = [ ];
        networking.firewall.allowedTCPPorts = [ 5751 ];
        services.niks3 = {
          enable = true;
          httpAddr = "0.0.0.0:5751";

          s3 = {
            endpoint = "s3.us-east-2.wasabisys.com"; # or your S3-compatible endpoint
            bucket = "cache.fu.io";
            useSSL = true;
            accessKeyFile = config.sops.secrets."niks3-s3-access-key".path;
            secretKeyFile = config.sops.secrets."niks3-s3-secret-key".path;
          };
          # API authentication token (minimum 36 characters)
          apiTokenFile = config.sops.secrets."niks3-api-token".path;

          # Signing keys for NAR signing
          signKeyFiles = [ config.sops.secrets."niks3-signing-key".path ];

          # Public cache URL (optional) - if exposed via https
          # Generates a landing page with usage instructions and public keys
          cacheUrl = "https://cache.fu.io";

          # Public niks3 server URL (optional). Set when the cache and niks3 server
          # are on different origins (e.g. reads from S3/CDN at cacheUrl), so the
          # landing page can fetch stats from ${serverUrl}/api/cache-stats.
          serverUrl = "https://niks3.fu.io";

          oidc.providers = {
            github = {
              issuer = "https://token.actions.githubusercontent.com";
              audience = "https://niks3.fu.io";
              boundClaims = {
                repository_owner = [ "georgyo" ];
              };
              boundSubject = [ "repo:georgyo/*:*" ];
            };
          };
        };
      };
  };
}
