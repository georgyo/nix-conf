{ inputs, self, ... }:
let
  inherit (inputs.self.lib.mk-os) linux;

  overlays =
    { ... }:
    {
      nixpkgs.overlays = [
        (import ../overlay.nix)
        inputs.sops-nix.overlays.default
        # self.overlay
        inputs.avalon.overlays.default
        inputs.blog_shamm_as.overlay
        (final: prev: {
          flakeInputs = inputs;

          cloudflare_ips_v4 = final.lib.strings.splitString "\n" (builtins.readFile inputs.cloudflare_ips_v4);
          cloudflare_ips_v6 = final.lib.strings.splitString "\n" (builtins.readFile inputs.cloudflare_ips_v6);

          beta = final.extend inputs.avalon-beta.overlays.default;

        })

      ];
    };
in
{
  flake.modules.nixos.hydra =
    { pkgs, ... }:
    {
      imports = [
        (self + /hosts/hydra)
        inputs.self.nixosModule
        overlays
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
      ];

    };

  flake.nixosConfigurations = {
    hydra = linux "hydra";
  };
}
