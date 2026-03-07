{ inputs, ... }:
{
  # flake = with inputs; {

  perSystem =
    { config, pkgs, ... }:
    let
      pkgs' = pkgs.extend inputs.sops-nix.overlays.default;
    in
    with pkgs';

    {
      devShells.default = mkShell {
        nativeBuildInputs = [
          sops-import-keys-hook
          age
        ];

        sopsPGPKeyDirs = [
          "./keys/hosts"
          "./keys/users"
        ];

      };
    };
}
