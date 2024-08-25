
{ config, pkgs, ... }:
{
  containers.forge = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ./common.nix "forge") ];

        services.forgejo = {
          enable = true;
          settings.server.DOMAIN = "forge.scalable.io";
        };
      };
  };
}
