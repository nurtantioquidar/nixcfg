{ pkgs, ... }:

{
  home = {
    username = "kerberos";
    homeDirectory = "/Users/kerberos";
    stateVersion = "26.05";
    packages = with pkgs; [
      colima
      docker
      docker-compose
      curl
      jq
      ripgrep
      htop
      tmux
      unzip
      neovim
      gh
      python3
      uv
      nodejs
    ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      DOCKER_HOST = "unix:///Users/kerberos/.colima/default/docker.sock";
    };
  };

  programs.zsh.enable = true;
  programs.git = {
    enable = true;
    settings.init.defaultBranch = "main";
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".ForwardAgent = false;
  };
}
