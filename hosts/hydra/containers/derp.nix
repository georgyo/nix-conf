{ config, pkgs, ... }:

let
  tailscale_derp = pkgs.tailscale.overrideAttrs (
    new: old: {
      subPackages = (old.subPackages or [ ]) ++ [
        "cmd/derper"
        "cmd/derpprobe"
      ];
    }
  );
in

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
          package = tailscale_derp;
          extraDaemonFlags = [
            "--tun=userspace-networking"
            "--socks5-server=localhost:1055"
            "--outbound-http-proxy-listen=localhost:1055"
          ];
        };

        systemd.services.derper = {
          enable = true;
          script = ''
            ${tailscale_derp}/bin/derper -hostname derp.scalable.io -verify-clients
          '';
          wantedBy = [ "multi-user.target" ];
        };

      };
  };
}
