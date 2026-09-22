{ pkgs, lib, ... } @ args:

let
  username = "kerberos";
  mkImports = import ../../lib/mkImports.nix args;
in
{
  imports = mkImports {
    inherit username;
    imports = [ ./services.nix ];
  };

  networking = {
    hostName = "luna";
    localHostName = "luna";
    computerName = "luna";
    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
      allowSigned = true;
    };
  };

  system.stateVersion = 6;
  system.primaryUser = username;
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  # Use upstream Nix on this fresh host; nix-darwin owns its daemon/settings.
  nix.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" ];

  power = {
    sleep.computer = "never";
    sleep.display = 10;
    restartAfterPowerFailure = true;
  };

  # Run the first activation at the mini's console. Never replace its existing
  # authorized_keys with a placeholder or lock out an unprepared user.
  system.activationScripts.preActivation.text = lib.mkBefore ''
    if ! /usr/bin/id ${username} >/dev/null 2>&1; then
      echo "Create the macOS account ${username} before activating luna." >&2
      exit 1
    fi
    if ! /usr/bin/ssh-keygen -l -f /Users/${username}/.ssh/authorized_keys >/dev/null 2>&1; then
      echo "Install your SSH public key in ${username}'s authorized_keys first." >&2
      exit 1
    fi
  '';
}
