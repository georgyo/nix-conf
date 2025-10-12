{ inputs, self, ... }:
let
  inherit (inputs.self.lib.mk-os) linux;
in
{
  flake.modules.nixos.bnas =
    { pkgs, ... }:
    {
      imports = [
        (import (self + /hosts/bnas/configuration.nix) inputs)
        inputs.agenix.nixosModules.default
        inputs.self.nixosModule
      ];
    };

  flake.nixosConfigurations = {
    bnas = linux "bnas";
  };
}
