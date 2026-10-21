# Originally adapted from https://github.com/vic/vix/blob/main/modules/community/lib/%2Bmk-os.nix
{ inputs, lib, ... }:
let
  flake.lib.mk-os = {
    inherit mkNixos linux;
  };

  linux = mkNixos "x86_64-linux" "nixos";

  # Upstream nixpkgs PRs not yet in nixos-unstable. Drop each once the flake
  # lock includes it; when the list is empty, nixpkgs is used unpatched.
  #
  # 576853: php 8.3.36 / 8.4.27 / 8.5.12 (CVE-2026-109618 / CVE-2026-109619).
  nixpkgsPatches = pkgs: [
    (pkgs.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/pull/576853.diff";
      hash = "sha256-pSrexWiMmeYtu12Nuqyu/BqJuwWP0EGOd3vPVv7aNFI=";
    })
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
