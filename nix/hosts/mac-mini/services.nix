{ pkgs, username, ... }:

{
  services.tailscale.enable = true;
  launchd.daemons.tailscaled.serviceConfig = {
    KeepAlive = true;
    ThrottleInterval = 10;
  };

  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      PubkeyAuthentication yes
      AuthenticationMethods publickey
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PermitEmptyPasswords no
      AllowUsers ${username}@100.64.0.0/10 ${username}@fd7a:115c:a1e0::/48
      AllowAgentForwarding no
      X11Forwarding no
      AllowTcpForwarding local
      GatewayPorts no
      MaxAuthTries 3
    '';
  };

  # A system LaunchDaemon running as kerberos, not a GUI-login LaunchAgent.
  # Foreground mode lets launchd supervise Colima. Verify cold boot on luna.
  launchd.daemons.luna-colima = {
    serviceConfig = {
      UserName = username;
      WorkingDirectory = "/Users/${username}";
      EnvironmentVariables = {
        HOME = "/Users/${username}";
        PATH = pkgs.lib.makeBinPath [ pkgs.colima pkgs.docker pkgs.openssh pkgs.coreutils ]
          + ":/usr/bin:/bin:/usr/sbin:/sbin";
      };
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--foreground"
        "--runtime"
        "docker"
        "--vm-type"
        "vz"
        "--cpu"
        "4"
        "--memory"
        "6"
        "--disk"
        "60"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "/var/log/luna-colima.log";
      StandardErrorPath = "/var/log/luna-colima.error.log";
    };
  };

  environment.etc."newsyslog.d/luna.conf".text = ''
    /var/log/luna-colima.log       640  5  1024  *  J
    /var/log/luna-colima.error.log 640  5  1024  *  J
  '';
}
