{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.syncthing = {
    enable = true;
    relay = {
      enable = true;
    };
    overrideDevices = true;
    overrideFolders = true;
    settings.devices = {
      diskstation = {
        id = "VPXZ7KY-UDU6LHI-TN5GB3D-LSHP2Y5-ZVMYQ3M-AYRB6HM-Q3UVHV4-WSE33AT";
        introducer = true;
      };
      "Pixel 4XL" = {
        id = "PGZG43A-4TABBPP-FSEHRYQ-JOLXZPD-UDLLLTR-2H75R4L-JTAE3ON-G4G2NA4";
      };
      glap = {
        id = "DWZC5WO-QSQDCMU-OFT5IW6-Y2J7FUN-JDVTPWY-O4EG4OU-A7DIWU4-EMGYLQV";
      };
      bigtower = {
        id = "T7QHX5X-6L47FJU-MXBSVUN-TSNZKMI-3QGFTG4-3H6XJ5Y-A6PPTET-DD3KFQE";
      };
    };
  };
}
