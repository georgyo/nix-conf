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

  containers.avalon = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ../common.nix "avalon") ];

        networking.firewall.allowedTCPPorts = [ 8001 ];

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
            WorkingDirectory = "${pkgs.avalon-online}/libexec/avalon/server";
            ProtectSystem = true;
            ProtectHome = true;
            RuntimeDirectory = "avalon";
            ConfigurationDirectory = "avalon";
          };
        };
      };
  };
}
