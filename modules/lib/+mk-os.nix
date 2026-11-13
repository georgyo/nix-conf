# Originally adapted from https://github.com/vic/vix/blob/main/modules/community/lib/%2Bmk-os.nix
{ inputs, lib, ... }:
let
  flake.lib.mk-os = {
    inherit mkNixos linux;
  };

  linux = mkNixos "x86_64-linux" "nixos";

  # Every *.patch file in ./patches at the repo root, in sorted order.
  patchesDir = ../../patches;
  localPatches = lib.pipe (builtins.readDir patchesDir) [
    (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".patch" n))
    lib.attrNames
    (map (n: patchesDir + "/${n}"))
  ];

  # Extra patches (e.g. pkgs.fetchpatch) can be appended here.
  nixpkgsPatches = pkgs: localPatches ++ [
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
