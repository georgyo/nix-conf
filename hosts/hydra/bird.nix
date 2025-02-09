{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.bird = {
    enable = true;
    config = builtins.readFile ./bird2.conf;
  };
}
