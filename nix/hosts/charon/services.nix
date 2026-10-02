{ config, pkgs, username, ... }:

let
  # Escape hatch for a manual install without a Tailscale auth key: true
  # opens key-only SSH on the public IP. provision.sh never needs it, because
  # the host joins the tailnet on first boot.
  bootstrapPublicSsh = false;

  # One-time key staged by scripts/provision.sh. Read only while the node
  # needs login, then deleted.
  tailscaleAuthKey = "/var/lib/secrets/tailscale/authkey";
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = tailscaleAuthKey;
    extraUpFlags = [ "--advertise-tags=tag:vps" "--hostname=charon" ];
  };
  systemd.services.tailscaled-autoconnect.serviceConfig.ExecStartPost =
    "${pkgs.coreutils}/bin/rm -f ${tailscaleAuthKey}";

  services.openssh = {
    enable = true;
    openFirewall = false;
    # A single host key, kept in 1Password and restored by provision.sh, so
    # reinstalls keep the same identity.
    hostKeys = [{ path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }];
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
