{
  config,
  pkgs,
  lib,
  ...
}:

{

  services.heisenbridge = {
    enable = true;
    owner = "@georgyo:nycr.chat";
    homeserver = "https://nycr.chat";
  };
}
