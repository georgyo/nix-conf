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
        };

        systemd.services.derper = {
          enable = true;
          script = ''
            ${tailscale_derp} -hostname derp.scalable.io -verify-clients
          '';
          wantedBy = [ "multi-user.target" ];
        };

      };
  };
}
