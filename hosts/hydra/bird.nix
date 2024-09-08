{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.bird2 = {
    enable = true;
    config = builtins.readFile ./bird2.conf;
  };
}
