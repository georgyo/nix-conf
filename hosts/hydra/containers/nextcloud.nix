{ config, pkgs, ... }:
{
  containers.nextcloud = {
    autoStart = true;
    hostBridge = "virtbr0";
    privateNetwork = true;
    extraFlags = [ "-U" ];

    config =
      { ... }:
      {
        nixpkgs.pkgs = pkgs;
        imports = [ (import ./common.nix "nextcloud") ];
      };
  };
}
