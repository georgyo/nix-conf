{ inputs, self, ... }:
let
  inherit (inputs.self.lib.mk-os) linux;

  overlays =
    { lib, ... }:
    {
      nixpkgs.overlays = [
        inputs.sops-nix.overlays.default
        inputs.avalon.overlays.default
        inputs.blog_shamm_as.overlay
        (final: prev: {
          flakeInputs = inputs;

          cloudflare_ips_v4 = final.lib.filter (s: s != "") (
            final.lib.strings.splitString "\n" (builtins.readFile inputs.cloudflare_ips_v4)
          );
          cloudflare_ips_v6 = final.lib.filter (s: s != "") (
            final.lib.strings.splitString "\n" (builtins.readFile inputs.cloudflare_ips_v6)
          );

          beta = final.extend inputs.avalon-beta.overlays.default;

          nodejs-slim_20 = final.nodejs-slim;

          # Hugo 0.170 dropped the bundled LibSass, so the ananke theme's
          # css.Sass call now needs the Dart Sass binary on PATH. Drop this
          # once blog.shamm.as adds dart-sass to its own nativeBuildInputs.
          blog_shamm_as = prev.blog_shamm_as.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ final.dart-sass ];
          });

        })
      ];
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "surrealdb"
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
      ];

    };

  flake.nixosConfigurations = {
    hydra = linux "hydra";
  };
}
