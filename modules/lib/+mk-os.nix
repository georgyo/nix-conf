# Originally adapted from https://github.com/vic/vix/blob/main/modules/community/lib/%2Bmk-os.nix
{ inputs, lib, ... }:
let
  flake.lib.mk-os = {
    inherit mkNixos linux;
  };

  linux = mkNixos "x86_64-linux" "nixos";

  mkNixos =
    system: cls: name:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        inputs.self.modules.nixos.${cls}
        inputs.self.modules.nixos.${name}
        {
          networking.hostName = lib.mkDefault name;
          nixpkgs.hostPlatform = lib.mkDefault system;
          system.stateVersion = lib.mkDefault "25.11";
        }
      ];
    };
in
{
  inherit flake;
}
