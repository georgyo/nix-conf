{ config, pkgs, ... }:
{

  services.nginx.virtualHosts."avalon.onl" = {
    enableACME = true;
    quic = true;
    http3 = true;
    forceSSL = true;
    serverAliases = [
      "www.avalon.onl"
      "avalon.onl"
    ];
    locations."/" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://192.168.55.14:8001";
    };
  };

  services.nginx.virtualHosts."beta.avalon.onl" = {
    enableACME = true;
    quic = true;
    http3 = true;
    forceSSL = true;
    serverAliases = [
      "beta.avalon.onl"
    ];
    locations."/" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://192.168.55.14:8002";
    };
  };

  # Echo the Origin header back only for origins allowed to hit the API.
  services.nginx.appendHttpConfig = ''
    map $http_origin $avalon_api_cors {
      default "";
      "~^https://(www\.)?avalon\.onl$" $http_origin;
      "~^https?://localhost(:[0-9]+)?$" $http_origin;
      "~^https?://127\.0\.0\.1(:[0-9]+)?$" $http_origin;
    }
  '';

  services.nginx.virtualHosts."api.avalon.onl" = {
    enableACME = true;
    quic = true;
    http3 = true;
    forceSSL = true;
    locations."/".return = "404";
    locations."/api" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://192.168.55.14:8001";
      extraConfig = ''
        add_header Access-Control-Allow-Origin $avalon_api_cors always;
        add_header Access-Control-Allow-Methods "GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept, Origin, X-Requested-With, X-Avalon-Auth" always;
        add_header Access-Control-Allow-Credentials "true" always;
        add_header Access-Control-Max-Age 86400 always;
        add_header Vary Origin always;
        if ($request_method = OPTIONS) {
          return 204;
        }
      '';
    };
  };

  containers.avalon = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ../common.nix "avalon") ];

        networking.firewall.allowedTCPPorts = [
          8001
          8002
        ];

        systemd.services.avalon = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          environment = {
            FIREBASE_KEY_FILE = "/etc/avalon/firebase-key.json";
          };
          serviceConfig = {
            ExecStart = "${pkgs.avalon-online}/bin/avalon-server";
            User = "avalon";
            DynamicUser = true;
            # WorkingDirectory = "${pkgs.avalon-online}/libexec/avalon/server";
            ProtectSystem = true;
            ProtectHome = true;
            RuntimeDirectory = "avalon";
            ConfigurationDirectory = "avalon";
          };
        };

        systemd.services.avalon-beta = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          environment = {
            FIREBASE_KEY_FILE = "/etc/avalon/firebase-key.json";
            PORT = "8002";
          };
          serviceConfig = {
            ExecStart = "${pkgs.beta.avalon-online}/bin/avalon-server";
            User = "avalon";
            DynamicUser = true;
            ProtectSystem = true;
            ProtectHome = true;
            RuntimeDirectory = "avalon";
            ConfigurationDirectory = "avalon";
          };
        };
      };
  };
}
