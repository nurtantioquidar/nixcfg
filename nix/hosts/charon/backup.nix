_:

let
  # Root-only and outside the flake. Holds `repository` (restic URL),
  # `password` (repository key, also kept in 1Password) and `env`
  # (object-storage credentials). See docs/charon-setup.md.
  secrets = "/var/lib/secrets/restic";
  secretFiles = [ "${secrets}/repository" "${secrets}/password" "${secrets}/env" ];
in
{
  # Every application keeps its state in /srv/<app>; everything else on
  # charon is rebuildable from this flake.
  systemd.tmpfiles.rules = [
    "d /srv 0755 root root -"
    "d /var/lib/secrets 0700 root root -"
    "d ${secrets} 0700 root root -"
  ];

  services.restic.backups.offsite = {
    initialize = true;
    repositoryFile = "${secrets}/repository";
    passwordFile = "${secrets}/password";
    environmentFile = "${secrets}/env";
    paths = [ "/srv" ];
    timerConfig = {
      OnCalendar = "19:00"; # 02:00 WIB
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    runCheck = true;
    checkOpts = [ "--read-data-subset=2%" ];
  };

  # Skip, rather than fail, until the credentials are installed.
  systemd.services.restic-backups-offsite.unitConfig.ConditionPathExists = secretFiles;
}
