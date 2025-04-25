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

    cloudflare_ips_v4 = {
      url = "https://www.cloudflare.com/ips-v4";
      flake = false;
    };
    cloudflare_ips_v6 = {
      url = "https://www.cloudflare.com/ips-v6";
      flake = false;
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
      lib = import (nixpkgs + /lib);
      overlay = import ./overlay.nix;
      sharedOverlays = [
        overlay
        sops-nix.overlays.default
        # self.overlay
        avalon.overlays.default
        blog_shamm_as.overlay
        (final: prev: {
          flakeInputs = inputs;

          cloudflare_ips_v4 = final.lib.strings.splitString "\n" (builtins.readFile inputs.cloudflare_ips_v4);
          cloudflare_ips_v6 = final.lib.strings.splitString "\n" (builtins.readFile inputs.cloudflare_ips_v6);

        })
      ];
    in
    utils.lib.mkFlake rec {
      inherit
        self
        inputs
        overlay
        sharedOverlays
        ;

      channels.default = {
        input = nixpkgs;

        overlays = sharedOverlays ++ [ overlay ];
        config = {
          permittedInsecurePackages = [ "olm-3.2.16" ];
          allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
             "nvidia-x11"
           ];

        };
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

      channels.cudaDefault = channels.default // {
        config = {
          cudaSupport = true;
        };
      };

      hostDefaults = {
        channelName = "default";
        modules = [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
        ];
      };

      hosts.hydra.modules = [ ./hosts/hydra ];

      outputsBuilder = channels: {
        formatter = channels.default.nixfmt-rfc-style;
        # legacyPackages = channels.default;
        packages =  {

          inherit (channels.default) blog_shamm_as;


          home-env =
            with channels.cudaDefault;
            buildEnv {
              name = "home-env";
              extraOutputsToInstall = [
                "man"
                "doc"
              ];
              paths = with pkgs; [
                buck2
                git-bug
                git-absorb
                hugo
                hydra-check
                nix-index
                nix-update
                nixd
                nixf
                nixfmt-rfc-style
                usql
                watchman
                htop-vim
              ];
              postBuild = ''
                if [ -x $out/bin/install-info -a -w $out/share/info ]; then
                  shopt -s nullglob
                  for i in $out/share/info/*.info $out/share/info/*.info.gz; do
                      $out/bin/install-info $i $out/share/info/dir
                  done
                fi
              '';

            };

  opengl_dir = channels.default.callPackage  (
    {
      buildEnv,
      mesa,
      linuxPackages,
    }:
    buildEnv {
      name = "opengl_dir";
      paths = [
        mesa.drivers
        linuxPackages.nvidia_x11.out
      ];

    }
  ) { };
        };

        devShell =
          with channels.default;
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
      };

    };

}
