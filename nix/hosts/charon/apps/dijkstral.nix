{ ... }:

# Hosted Dijkstral's service (github.com/nurtantioquidar/tundral, products/dijkstral/service;
# DIJKSTRAL_HOSTED_DESIGN.md §4). Public at dijkstral.tundral.ai through a locally managed
# Cloudflare Tunnel: cloudflared dials out, so no port opens on charon. The web app joins as a
# second container when it exists, as the tunnel's catch-all.
let
  site = import ./site.nix;
  port = 8095;
  # db/ (SQLite) and repos/ (customer checkouts and graphs, rebuildable from GitHub).
  dataDir = "/srv/dijkstral";
  # DIJKSTRAL_SERVICE_WEBHOOK_SECRET, DIJKSTRAL_SERVICE_INTERNAL_TOKEN,
  # DIJKSTRAL_SERVICE_GITHUB_APP_ID and DIJKSTRAL_SERVICE_GITHUB_PRIVATE_KEY_BASE64 (the app's
  # PEM key, base64 on one line); save-secrets.sh keeps them in 1Password.
  envFile = "/var/lib/secrets/dijkstral/env";
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
    # main at 05b387a (2026-10-29).
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

  systemd.services.docker-dijkstral-service = {
    partOf = [ "charon-apps.target" ];
    wantedBy = [ "charon-apps.target" ];
    unitConfig.ConditionPathExists = [ envFile ghcrToken "!${site.restorePending}" ];
  };

  services.cloudflared = {
    enable = true;
    tunnels.${tunnelId} = {
      credentialsFile = tunnelCredentials;
      # Only MCP and GitHub's webhooks reach the service: /internal/* and /healthz never
      # leave charon. Mirrored in the tundral repository's deploy/.
      ingress."dijkstral.tundral.ai" = {
        service = "http://127.0.0.1:${toString port}";
        path = "^/(mcp/[^/]+/[^/]+|github/webhook)$";
      };
      default = "http_status:404";
    };
  };
  systemd.services."cloudflared-tunnel-${tunnelId}".unitConfig.ConditionPathExists = [
    tunnelCredentials
  ];

  # Customer code never leaves charon; after a restore the service rebuilds it from GitHub.
  services.restic.backups.offsite.exclude = [ "${dataDir}/repos" ];
}
