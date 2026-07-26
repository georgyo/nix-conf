{
  # Temporary nixpkgs workarounds.
  #
  # python3Packages.cheetah3 (a sabnzbd dependency) fails its
  # pythonMetadataCheckPhase because the distribution it installs is named
  # "ct3", not "cheetah3". Upstream fixed this by renaming the attribute
  # (nixpkgs e0c8b3d1f3, 2026-07-24), which is not in nixos-unstable yet.
  # Drop this file once the flake lock includes that commit.
  flake.modules.nixos.nixos = {
    nixpkgs.overlays = [
      (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev: {
            cheetah3 = pyprev.cheetah3.overridePythonAttrs (_: {
              pname = "ct3";
            });
          })
        ];
      })
    ];
  };
}
