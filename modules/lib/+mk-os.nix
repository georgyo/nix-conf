# Originally adapted from https://github.com/vic/vix/blob/main/modules/community/lib/%2Bmk-os.nix
{ inputs, lib, ... }:
let
  flake.lib.mk-os = {
    inherit mkNixos linux;
  };

  linux = mkNixos "x86_64-linux" "nixos";

  # Upstream nixpkgs PRs not yet in nixos-unstable. Drop each once the flake
  # lock includes it; when the list is empty, nixpkgs is used unpatched.
  nixpkgsPatches = pkgs: [
  ];

  # Re-instantiate the nixpkgs flake from the patched source, keeping the
  # original input's rev/lastModified metadata.
  patchNixpkgs =
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      src = pkgs.applyPatches {
        name = "nixpkgs-patched";
        src = inputs.nixpkgs;
        patches = nixpkgsPatches pkgs;
      };
      self =
        inputs.nixpkgs
        // {
          inherit (src) outPath;
        }
        // (import "${src}/flake.nix").outputs { inherit self; };
    in
    if nixpkgsPatches pkgs == [ ] then inputs.nixpkgs else self;

  mkNixos =
    system: cls: name:
    (patchNixpkgs system).lib.nixosSystem {
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
