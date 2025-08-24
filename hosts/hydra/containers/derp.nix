{ config, pkgs, ... }:

{
  containers.derp = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ./common.nix "derp") ];

        networking.firewall.allowedUDPPorts = [ 443 ];
        networking.firewall.allowedTCPPorts = [
          80
          443
          3478
        ];
        networking.firewall.extraCommands = '''';

        services.tailscale = {
          enable = true;
          extraDaemonFlags = [
            "--tun=userspace-networking"
            "--socks5-server=localhost:1055"
            "--outbound-http-proxy-listen=localhost:1055"
          ];
        };

        services.tailscale.derper = {
          enable = true;
          verifyClients = true;
          domain = "derp.scalable.io";
        };

        services.nginx.package = pkgs.nginxQuic;
        services.nginx.virtualHosts."derp.scalable.io" = {
          enableACME = true;
          quic = true;
          locations."/debug/".extraConfig = ''
            allow 100.64.0.0/10;
            deny all;
          '';
        };
      };
  };
}
