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
  # 574050, 576777: nodejs_24 24.21.0 -> 24.22.0 -> 24.22.1 (staging).
  # 576776, 576775: nodejs_26 26.12.1, nodejs_22 22.23.4.
  # nodejs-brotli-cve.patch: patched brotli the new node releases need to build.
  nixpkgsPatches = pkgs: [
    (pkgs.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/pull/576853.diff";
      hash = "sha256-pSrexWiMmeYtu12Nuqyu/BqJuwWP0EGOd3vPVv7aNFI=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/pull/574050.patch";
      hash = "sha256-J/ah4yfz8O/Kp7wXukbbzhmbcn0RdQe3jqYMR+Hbimg=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/pull/576777.patch";
      hash = "sha256-csY2zCMoNpV9JONv29v3Uk0G9LtiBGZboJ9/qah0OwM=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/pull/576776.patch";
      hash = "sha256-3yKX9QUi+OaIhyxV1sj2uVWsNjbUZslKOxBIZhGXhu8=";
    })
    (pkgs.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/pull/576775.patch";
      hash = "sha256-j2TIJ+O/6F913YVtFlbR8bWx5HgEP+Bfe1vKATFjhcU=";
    })
    ../../patches/nodejs-brotli-cve.patch
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
