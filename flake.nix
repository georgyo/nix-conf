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
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    avalon = {
      url = "github:georgyo/avalon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blog_shamm_as = {
      url = "github:georgyo/blog.shamm.as";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      utils,
      nixpkgs,
      sops-nix,
      home-manager,
      flake-utils,
      avalon,
      blog_shamm_as,
      ...
    }@inputs:
    let
      overlay = import ./overlay.nix;
      sharedOverlays = [
        sops-nix.overlays.default
        self.overlay
        avalon.overlays.default
        blog_shamm_as.overlay
        (prev: final: { flakeInputs = inputs; })
      ];
    in
    utils.lib.mkFlake {
      inherit
        self
        inputs
        overlay
        sharedOverlays
        ;

      channels.default = {
        input = nixpkgs;
        config = { };
        patches =
          let
            patchDir = ./patches;
          in
          builtins.map (n: patchDir + ("/" + n)) (
            builtins.filter (n: builtins.match ".*\\.patch" n != null) (
              builtins.attrNames (builtins.readDir patchDir)
            )
          );
      };

      hostDefaults = {
        channelName = "default";
        modules = [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
        ];
      };

      hosts.hydra.modules = [ ./hosts/hydra ];
    }
    // (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = sharedOverlays;
        };

        pkgsCuda = import nixpkgs {
          inherit system;
          cudaSupport = true;
          overlays = sharedOverlays;
        };
      in
      {

        formatter = pkgs.nixfmt-rfc-style;

        packages.home-env =
          with pkgsCuda;
          buildEnv {
            name = "home-env";
            extraOutputsToInstall = [
              "man"
              "doc"
            ];
            paths = [
              buck2
              git-bug
              git-absorb
              guix
              hugo
              hydra-check
              jujutsu
              nix-du
              nix-index
              nix-update
              nixd
              nixfmt-rfc-style
              sapling
              usql
              watchman
            ];

          };

        devShell =
          with pkgs;
          mkShell {
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
