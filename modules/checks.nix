{ self, lib, ... }:
{
  perSystem =
    { system, config, ... }:
    {
      checks =
        lib.mapAttrs' (name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel) (
          lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) {
            inherit (self.nixosConfigurations) hydra bnas;
          }
        )
        // {
          inherit (config.packages) flake-inputs;
        };
    };
}
