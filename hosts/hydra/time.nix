{
  config,
  lib,
  pkgs,
  ...
}:

{

  # Set your time zone.
  time.timeZone = "America/New_York";
  time.hardwareClockInLocalTime = true;

  networking.timeServers = [
    "time1.facebook.com"
    "time2.facebook.com"
    "time3.facebook.com"
    "time4.facebook.com"
    "time5.facebook.com"
    "time1.google.com"
    "time2.google.com"
    "time3.google.com"
    "time4.google.com"
    "time.cloudflare.com"
    "time.aws.com"
    "time.nist.gov"
    "time.apple.com"
  ];

  services.chrony = {
    enable = true;
    extraConfig = ''
      minsources 5
      combinelimit 5
    '';
  };
}
