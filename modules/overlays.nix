{
  # Temporary nixpkgs workarounds.
  #
  # python3Packages.cheetah3 (a sabnzbd dependency) fails its
  # pythonMetadataCheckPhase because the distribution it installs is named
  # "ct3", not "cheetah3". Upstream fixed this by renaming the attribute
  # (nixpkgs e0c8b3d1f3, 2026-07-24), which is not in nixos-unstable yet.
  # Drop this file once the flake lock includes that commit.
  #
  # mosh: abseil 20260817 headers need C++20 (std::partial_ordering), but
  # mosh's configure forces -std=gnu++17. CXXFLAGS comes after it on the
  # command line, so it wins.
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

        mosh = prev.mosh.overrideAttrs (old: {
          env = (old.env or { }) // {
            CXXFLAGS = "-std=gnu++20";
          };
        });
      })
    ];
  };
}
