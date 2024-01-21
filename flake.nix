{
  description = "HOME";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils = {
      url = "github:gytis-ivaskevicius/flake-utils-plus";
      inputs.flake-utils.follows = "flake-utils";
    };
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    avalon = {
      url = "github:georgyo/avalon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, utils, nixpkgs, sops-nix, home-manager, flake-utils, avalon, ... }@inputs:
    let
      overlay = import ./overlay.nix;
      sharedOverlays = [
        sops-nix.overlays.default
        self.overlay
        avalon.overlays.default
        (prev: final: { flakeInputs = inputs; })
      ];
    in
    utils.lib.mkFlake
      {
        inherit self inputs overlay sharedOverlays;

        channels.default = {
          input = nixpkgs;
          config = { };
          patches =
            let
              patchDir = ./patches;
            in
            builtins.map
              (n: patchDir + ("/" + n))
              (builtins.filter (n: builtins.match ".*\\.patch" n != null) (builtins.attrNames (builtins.readDir patchDir)));
        };

        hostDefaults = {
          channelName = "default";
          modules = [
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
          ];
        };

        hosts.hydra.modules = [
          ./hosts/hydra
        ];

      }
    // (flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; overlays = sharedOverlays; }; in {

        formatter = pkgs.nixpkgs-fmt;

        devShell = with pkgs; mkShell {
          nativeBuildInputs = [
            sops-import-keys-hook
            age
          ];

          sopsPGPKeyDirs = [
            "./keys/hosts"
            "./keys/users"
          ];
        };
      }
    ));
}
