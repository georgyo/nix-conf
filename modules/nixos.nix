{ inputs, self, ... }:
{
  flake.modules.nixos.nixos =
    { pkgs, ... }:
    {
      services.dbus.implementation = "broker";

      environment.systemPackages = [
        pkgs.gdu
        inputs.myemacs.packages.${pkgs.system}.default
        inputs.myemacs.packages.${pkgs.system}.e
      ];
    };
}
