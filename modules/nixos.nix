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
          extra-substituters = [ "https://cache.fu.io" ];
          extra-trusted-public-keys = [
            "georgyo-1:2yY6X+H3y0xp9e94WQsjXlWNDX2ElWWrp5P89pQ9zPM="
          ];
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
