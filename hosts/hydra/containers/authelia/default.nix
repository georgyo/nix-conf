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
      proxyPass = "http://192.168.55.19:9091";
    };
  };

  containers.authelia = {
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
          (import ../common.nix "authelia")
          pkgs.flakeInputs.sops-nix.nixosModules.sops
        ];

        networking.firewall.allowedUDPPorts = [ ];
        networking.firewall.allowedTCPPorts = [ 9091 ];
        sops = {
          age = {
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };
          defaultSopsFile = ./secrets/secrets.yaml;
          secrets.fuStorageEncryptionKey = {
            owner = "authelia-fu";
            mode = "0400";
          };
          secrets.fuSessionSecret = {
            owner = "authelia-fu";
            mode = "0400";
          };
          secrets.fuOidcIssuerPrivateKey = {
            owner = "authelia-fu";
            mode = "0400";
          };
          secrets.fuOidcHmacSecret = {
            owner = "authelia-fu";
            mode = "0400";
          };
          secrets.fuJwtSecret = {
            owner = "authelia-fu";
            mode = "0400";
          };
        };

        services.authelia.instances.fu = {
          enable = true;
          settings = {
            theme = "auto";
            default_2fa_method = "webauthn";
            authentication_backend.file.path = "/etc/authelia/users_database.yml";
            session.domain = "auth.fu.io";
            storage.local.path = "/tmp/db.sqlite3";
            access_control.default_policy = "one_factor";
            notifier.filesystem.filename = "/tmp/notifications.txt";
            webauthn.enable_passkey_login = true;
              
          };
          secrets = {
            storageEncryptionKeyFile = config.sops.secrets.fuStorageEncryptionKey.path;
            sessionSecretFile = config.sops.secrets.fuSessionSecret.path;
            # oidcIssuerPrivateKeyFile = config.sops.secrets.fuOidcIssuerPrivateKey.path;
            # oidcHmacSecretFile = config.sops.secrets.fuOidcHmacSecret.path;
            jwtSecretFile = config.sops.secrets.fuJwtSecret.path;
          };

        };

        environment.etc."authelia/users_database.yml" = {
          mode = "0400";
          user = "authelia-fu";
          text = ''
            users:
              bob:
                disabled: false
                displayname: bob
                # password of password
                password: $argon2id$v=19$m=65536,t=3,p=4$2ohUAfh9yetl+utr4tLcCQ$AsXx0VlwjvNnCsa70u4HKZvFkC8Gwajr2pHGKcND/xs
                email: bob@jim.com
                groups:
                  - admin
                  - dev
          '';
        };

      };
  };
}
