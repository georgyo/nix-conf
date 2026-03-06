{
  config,
  lib,
  pkgs,
  ...
}:

{

  services.nginx.virtualHosts."surreal.fu.io" = {
    enableACME = true;
    quic = true;
    http3 = true;
    forceSSL = true;
    serverAliases = [
      "surreal.fu.io"
    ];
    locations."/" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://192.168.55.17:8000";
    };
  };

  containers.surrealdb = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ../common.nix "surrealdb") ];

        networking.firewall.allowedUDPPorts = [ ];
        networking.firewall.allowedTCPPorts = [ 8000 ];
        systemd.services.surrealdb.serviceConfig.ProcSubset = lib.mkForce "all";
        services.surrealdb = {
          enable = true;
          package = pkgs.callPackage ./package.nix { };
          host = "0.0.0.0";
          extraFlags = [
            "--allow-all"
            "--deny-net"
            "--deny-funcs http"
            "--client-ip" "X-Forwarded-For"
          ];
        };

      };
  };
}
