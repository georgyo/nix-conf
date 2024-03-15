{ config, lib, pkgs, ... }:

let
  my-python-packages = python-packages: with python-packages; [ setuptools ];
  my-python3 = pkgs.python3.withPackages my-python-packages;
in
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    [
      wget
      gnugrep
      ripgrep
      vim
      neovim
      curl
      htop
      dstat
      docker-compose
      whois
      my-python3
      wireguard-tools
      # mailutils
      lsof
      lsb-release
      jq
      yq
      tcpdump
      git
      tig
      jujutsu
      gh
      usql
      gitAndTools.git-hub
      gitAndTools.hub
      btrfs-progs
      nftables
      openssl
      nixpkgs-fmt
      nix-du
      graphviz-nox
      # pantalaimon
      gnupg
      grml-zsh-config
      atuin
      rclone
      restic
      spacevim
      iftop
    ];
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LESS = "FRSX";
  };

  programs.neovim = { enable = true; defaultEditor = true; viAlias = true; };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  programs.mtr.enable = true;
  programs.mosh.enable = true;
  programs.tmux.enable = true;
  programs.zsh = rec {
    enable = true;
    #promptInit = "";
    enableBashCompletion = true;
    shellInit = ''
      source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
    '';
    loginShellInit = shellInit;
    interactiveShellInit = shellInit;

  };
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
}
