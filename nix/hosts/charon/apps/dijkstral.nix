{ pkgs, ... }:

# Hosted Dijkstral (github.com/nurtantioquidar/tundral, products/dijkstral; DIJKSTRAL_HOSTED_DESIGN.md
# §4): the service (webhooks, builds, MCP) and the web console (sign-in, repositories, tokens).
# Public at dijkstral.tundral.ai through a locally managed Cloudflare Tunnel: cloudflared dials
# out, so no port opens on charon.
let
  site = import ./site.nix;
  port = 8095;
  webPort = 3002;
  # db/ (SQLite) and repos/ (customer checkouts and graphs, rebuildable from GitHub).
  dataDir = "/srv/dijkstral";
  # DIJKSTRAL_SERVICE_WEBHOOK_SECRET, DIJKSTRAL_SERVICE_INTERNAL_TOKEN,
  # DIJKSTRAL_SERVICE_GITHUB_APP_ID and DIJKSTRAL_SERVICE_GITHUB_PRIVATE_KEY_BASE64 (the app's
  # PEM key, base64 on one line); save-secrets.sh keeps them in 1Password.
  envFile = "/var/lib/secrets/dijkstral/env";
  # The console's DIJKSTRAL_SESSION_SECRET, DIJKSTRAL_GITHUB_CLIENT_ID,
  # DIJKSTRAL_GITHUB_CLIENT_SECRET and DIJKSTRAL_SERVICE_INTERNAL_TOKEN (the service's own).
  webEnvFile = "/var/lib/secrets/dijkstral/web-env";
  # A classic GitHub token with read:packages only, for the private image. Not an env file, so
  # save-secrets.sh skips it: a lost token is replaced with a new one.
  ghcrToken = "/var/lib/secrets/dijkstral/ghcr-token";
  # From `cloudflared tunnel create dijkstral`. A lost credentials file is fetched again with
  # `cloudflared tunnel token --cred-file <file> dijkstral`.
  tunnelId = "00000000-0000-0000-0000-000000000000"; # TODO: the tunnel's id
  tunnelCredentials = "/var/lib/secrets/cloudflared/${tunnelId}.json";
  # The image's non-root user.
  uid = "65532";
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 ${uid} ${uid} -"
    "d /var/lib/secrets/dijkstral 0700 root root -"
    "d /var/lib/secrets/cloudflared 0700 root root -"
  ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.dijkstral-service = {
    # Built by the tundral repository's dijkstral-service-image workflow; pinned by the digest
    # from that run's summary. Upgrades: change the digest, then rebuild.
    # main at 05b387a (2026-10-29). TODO: re-pin after the service changes of 2026-11-04 (token
    # listing, public repositories only) reach main.
    image = "ghcr.io/nurtantioquidar/dijkstral-service@sha256:c26e11191f9af75f2df1dea5bd1412af25cfea803404ed6c88282051c73a8f32";
    login = {
      registry = "ghcr.io";
      username = "nurtantioquidar";
      passwordFile = ghcrToken;
    };
    user = "${uid}:${uid}";
    ports = [ "127.0.0.1:${toString port}:8095" ];
    volumes = [ "${dataDir}:/data" ];
    environmentFiles = [ envFile ];
    environment.NO_COLOR = "1";
    extraOptions = [
      # Reaps git's children when a timed-out fetch is killed.
      "--init"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--read-only"
      "--tmpfs=/tmp"
      # One build at a time, capped at 300k nodes (the service's free-tier limits).
      "--memory=3g"
      "--pids-limit=256"
    ];
  };

  virtualisation.oci-containers.containers.dijkstral-web = {
    # Built by the tundral repository's dijkstral-web-image workflow; pinned by digest as above.
    image = "ghcr.io/nurtantioquidar/dijkstral-web@sha256:0000000000000000000000000000000000000000000000000000000000000000"; # TODO: digest from the first run
    login = {
      registry = "ghcr.io";
      username = "nurtantioquidar";
      passwordFile = ghcrToken;
    };
    environmentFiles = [ webEnvFile ];
    environment = {
      DIJKSTRAL_PUBLIC_URL = "https://dijkstral.tundral.ai";
      DIJKSTRAL_GITHUB_APP_SLUG = "dijkstral"; # TODO: the app's URL name, if GitHub gave another
      DIJKSTRAL_SERVICE_URL = "http://127.0.0.1:${toString port}";
      # Host networking, so it reaches the service on loopback; listen on loopback only.
      HOSTNAME = "127.0.0.1";
      PORT = toString webPort;
    };
    extraOptions = [
      "--network=host"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--read-only"
      "--tmpfs=/tmp"
      "--memory=512m"
    ];
  };

  systemd.services.docker-dijkstral-web = {
    after = [ "docker-dijkstral-service.service" ];
    partOf = [ "charon-apps.target" ];
    wantedBy = [ "charon-apps.target" ];
    unitConfig.ConditionPathExists = [ webEnvFile ghcrToken "!${site.restorePending}" ];
  };

  systemd.services.docker-dijkstral-service = {
    partOf = [ "charon-apps.target" ];
    wantedBy = [ "charon-apps.target" ];
    unitConfig.ConditionPathExists = [ envFile ghcrToken "!${site.restorePending}" ];
  };

  # The tunnel, with the same ingress as the tundral repository's deploy/cloudflared-dijkstral.yml:
  # only MCP and GitHub's webhooks reach the service (/internal/* and /healthz never leave
  # charon); every other path on the host is the console; anything else is a 404. Run from its own
  # unit because services.cloudflared keys ingress by hostname, so it cannot route two paths of one
  # host to two services.
  systemd.services.cloudflared-dijkstral = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = [ tunnelCredentials ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config ${pkgs.writeText "cloudflared-dijkstral.yml" ''
        tunnel: ${tunnelId}
        credentials-file: /run/credentials/cloudflared-dijkstral.service/tunnel.json
        ingress:
          - hostname: dijkstral.tundral.ai
            path: ^/(mcp/[^/]+/[^/]+|github/webhook)$
            service: http://127.0.0.1:${toString port}
          - hostname: dijkstral.tundral.ai
            service: http://127.0.0.1:${toString webPort}
          - service: http_status:404
      ''} run";
      LoadCredential = "tunnel.json:${tunnelCredentials}";
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Customer code never leaves charon; after a restore the service rebuilds it from GitHub.
  services.restic.backups.offsite.exclude = [ "${dataDir}/repos" ];
}
