{ pkgs, ... }:

let
  # Root-only and outside the flake. Holds `repository` (restic URL),
  # `password` (repository key, also kept in 1Password) and `env`
  # (object-storage credentials). See docs/charon-setup.md.
  secrets = "/var/lib/secrets/restic";
  secretFiles = [ "${secrets}/repository" "${secrets}/password" "${secrets}/env" ];

  # Restores /srv from the latest snapshot onto a fresh install. Refuses to
  # overwrite existing application data unless --force is given.
  charonRestore = pkgs.writeShellApplication {
    name = "charon-restore";
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        echo "run as root: sudo charon-restore" >&2
        exit 1
      fi
      existing=$(find /srv -mindepth 1 -maxdepth 1 ! -name restic-canary -print -quit)
      if [ -n "$existing" ] && [ "''${1:-}" != "--force" ]; then
        echo "/srv already has data ($existing); rerun with --force to overwrite" >&2
        exit 1
      fi
      systemctl stop charon-apps.target
      /run/current-system/sw/bin/restic-offsite restore latest --target / --include /srv
      systemctl start charon-apps.target
    '';
  };
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

  # Application services set `partOf` and `wantedBy` to this target, so a
  # restore can stop and restart all of them.
  systemd.targets.charon-apps.wantedBy = [ "multi-user.target" ];
  environment.systemPackages = [ charonRestore ];

  # Skip, rather than fail, until the credentials are installed.
  systemd.services.restic-backups-offsite.unitConfig.ConditionPathExists = secretFiles;
}
