{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.geoipupdate = {
    enable = true;
    settings.AccountID = 367173;
    settings.LicenseKey = {
      _secret = "/etc/geoip/license.key";
    };
    settings.EditionIDs = [
      "GeoLite2-ASN"
      "GeoLite2-City"
      "GeoLite2-Country"
    ];
  };
}
