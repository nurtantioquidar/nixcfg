{ config, username, ... }:

let
  # Phase 1 (install): SSH is reachable on the public IP, key-only, so the
  # first `tailscale up` can be run. Set to false and rebuild once
  # `ssh hades@charon` works over the tailnet; SSH then accepts Tailscale
  # source addresses only, and port 22 closes on the public interface.
  bootstrapPublicSsh = true;
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      AllowUsers =
        if bootstrapPublicSsh
        then [ username ]
        else [ "${username}@100.64.0.0/10" "${username}@fd7a:115c:a1e0::/48" ];
      AllowAgentForwarding = false;
      AllowTcpForwarding = "local";
      X11Forwarding = false;
      GatewayPorts = "no";
      MaxAuthTries = 3;
    };
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    # Public web ports open only when Caddy is added for monet.sh.
    allowedTCPPorts = if bootstrapPublicSsh then [ 22 ] else [ ];
    logRefusedConnections = false;
  };

  # Docker writes its own iptables rules, so published ports bypass the NixOS
  # firewall. Binding unqualified `-p`/`ports:` to loopback keeps them private;
  # expose services through Caddy or `tailscale serve` instead.
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      ip = "127.0.0.1";
      log-driver = "local";
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
