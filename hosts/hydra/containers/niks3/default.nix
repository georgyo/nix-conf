{ config, pkgs, ... }:
{
  containers.niks3 = {
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
         # secrets."pocketid.env" = {
         #   sopsFile = ./secrets/pocketid.env;
         #   format = "dotenv";
         #   restartUnits = [
         #     "pocket-id.service"
         #   ];
         # };
        };
        services.niks3 = {
          enable = true;

          s3 = {
            endpoint = "s3.us-east-2.wasabisys.com"; # or your S3-compatible endpoint
            bucket = "nix";
            useSSL = true;
            accessKeyFile = "/run/secrets/s3-access-key";
            secretKeyFile = "/run/secrets/s3-secret-key";
          };
          # API authentication token (minimum 36 characters)
          apiTokenFile = "/run/secrets/niks3-api-token";

          # Signing keys for NAR signing
          signKeyFiles = [ "/run/secrets/niks3-signing-key" ];

          # Public cache URL (optional) - if exposed via https
          # Generates a landing page with usage instructions and public keys
          cacheUrl = "https://s3.us-east-2.wasabisys.com/nix";

          # Public niks3 server URL (optional). Set when the cache and niks3 server
          # are on different origins (e.g. reads from S3/CDN at cacheUrl), so the
          # landing page can fetch stats from ${serverUrl}/api/cache-stats.
          serverUrl = "https://niks3.fu.io";
        };
      };
  };
}
