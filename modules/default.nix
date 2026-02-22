{ inputs, ... }:
{
  flake = with inputs; {
    # Default overlay, for use in dependent flakes
    overlay = final: prev: {
      inherit inputs;
      myemacs = inputs.myemacs.packages.${final.system}.default;
    };

    # # Same idea as overlay but a list or attrset of them.
    overlays = {
      default = self.overlay;
    };

    # Default module, for use in dependent flakes. Deprecated, use nixosModules.default instead.
    nixosModule =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        options = { };
        config = {
          environment.systemPackages = [
            agenix.packages.x86_64-linux.default
            pkgs.ghostty.terminfo
          ];
          nixpkgs.overlays = [
            self.overlay
          ];
          environment.variables.EDITOR = lib.mkOverride 900 "emacs";
          nix.registry = {
            nixpkgs.to = {
              type = "path";
              path = pkgs.path;
            };
          };
        };
      };

    # Same idea as nixosModule but a list or attrset of them.
    nixosModules = {
      default = self.nixosModule;
    };

  };
  systems = [ "x86_64-linux" ];
  perSystem =
    { config, pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;
    };
}
