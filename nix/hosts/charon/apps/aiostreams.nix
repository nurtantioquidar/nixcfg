{ config, ... }:

let
  site = import ./site.nix;
  port = 3000;
  dataDir = "/srv/aiostreams";
  # SECRET_KEY (never changes: it encrypts every stored config) and
  # AIOSTREAMS_AUTH. Debrid keys are entered in the app and live in its
  # database instead.
  envFile = "/var/lib/secrets/aiostreams/env";
  # Distroless "nonroot"; the image itself sets no user.
  uid = "65532";
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root -"
    "d ${dataDir}/data 0700 ${uid} ${uid} -"
  ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.aiostreams = {
    image = "ghcr.io/viren070/aiostreams:v2.35.7";
    user = "${uid}:${uid}";
    ports = [ "127.0.0.1:${toString port}:3000" ];
    volumes = [ "${dataDir}/data:/app/data" ];
    environmentFiles = [ envFile ];
    environment = {
      BASE_URL = "https://${site.tailnetHost}";
      DATABASE_URI = "sqlite://./data/db.sqlite";
      LOG_FORMAT = "json";
    };
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--read-only"
      "--tmpfs=/tmp"
      "--memory=1g"
    ];
  };

  systemd.services.docker-aiostreams = {
    partOf = [ "charon-apps.target" ];
    wantedBy = [ "charon-apps.target" ];
    unitConfig.ConditionPathExists = [ envFile "!${site.restorePending}" ];
  };

  # Tailnet-only HTTPS for Stremio; never Funnel. The serve config lives in
  # tailscaled state, so it is reapplied on every boot and reinstall.
  systemd.services.tailscale-serve-aiostreams = {
    after = [ "tailscaled-autoconnect.service" "docker-aiostreams.service" ];
    wants = [ "tailscaled-autoconnect.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Waits for Serve/HTTPS to be enabled on the tailnet otherwise; time
      # out and retry so it never blocks boot or a rebuild.
      TimeoutStartSec = 60;
      Restart = "on-failure";
      RestartSec = 15;
    };
    script = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 http://127.0.0.1:${toString port}";
  };

  # Caches and lookup datasets are downloaded again when missing.
  services.restic.backups.offsite.exclude = map (d: "${dataDir}/data/${d}") [
    "cache"
    "anime-database"
    "id-mappings"
    "scene-mappings"
    "seadex"
  ];
}
