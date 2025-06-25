{ config, pkgs, ... }:

{
  containers.grocy = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];
    enableTun = true;

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ./common.nix "grocy") ];

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
        networking.firewall.extraCommands = '''';

        services.grocy = {
          enable = true;
          hostName = "grocy.fu.io";
        };
      };
  };
}
