{ inputs, self, ... }:
{
  flake.modules.nixos.nixos =
    { pkgs, ... }:
    {
      services.dbus.implementation = "broker";

      environment.systemPackages = [
        pkgs.gdu
        # inputs.myemacs.packages.${pkgs.system}.default
        # inputs.myemacs.packages.${pkgs.system}.e
      ];

      nix = {
        settings = {
          builders-use-substitutes = true;
        };
        buildMachines =
          builtins.map
            (system: {
              hostName = "eu.nixbuild.net";
              inherit system;
              maxJobs = 100;
              supportedFeatures = [
                "benchmark"
                "big-parallel"
              ];
            })
            [
              "i686-linux"
              "x86_64-linux"
              "aarch64-linux"
              "armv7l-linux"
              "aarch64-darwin"
            ];

        distributedBuilds = false;
      };
    };
}
