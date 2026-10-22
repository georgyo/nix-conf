let
  shammas_user = "age17jww3vhjultwv2l7rhjj98k4qyuvzffnvlenuxkdl8vdmrv8zegqnz086d";
  users = [ shammas_user ];

  bnas_system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIgw62N+wiff/kK1t2Y1kuuQcqxr/XMAHvxDGMV6FJ5";
  seed_system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCxckTAyIYmD6DK4HB64A61CGDPg0eYcaF1ZVmWfE6M";
  systems = [ bnas_system ];

  default = systems ++ users;
in

{
  "wg-quick.age".publicKeys = default;
  "CF_API_KEY.age".publicKeys = default;
  "wg-netns.age".publicKeys = default;
  "traefik-forward-auth.age".publicKeys = default;
  "autobrr-session.age".publicKeys = default ++ [ seed_system ];
  "local-wg-key.age".publicKeys = default;
  "airportsilom_credentials.age".publicKeys = default;
  "sabnzbd.ini.age".publicKeys = default ++ [ seed_system ];
}
