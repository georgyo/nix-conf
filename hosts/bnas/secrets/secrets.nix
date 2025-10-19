let
  users = [ ];

  bnas_system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIgw62N+wiff/kK1t2Y1kuuQcqxr/XMAHvxDGMV6FJ5";
  seed_system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCxckTAyIYmD6DK4HB64A61CGDPg0eYcaF1ZVmWfE6M";
  systems = [ bnas_system ];
in

{
  "wg-quick.age".publicKeys = [ bnas_system ];
  "CF_API_KEY.age".publicKeys = [ bnas_system ];
  "wg-netns.age".publicKeys = [ bnas_system ];
  "autobrr-session.age".publicKeys = [
    bnas_system
    seed_system
  ];
  "local-wg-key.age".publicKeys = [ bnas_system ];
  "airportsilom_credentials.age".publicKeys = [ bnas_system ];
}
