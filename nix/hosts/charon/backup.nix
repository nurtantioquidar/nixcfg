{ pkgs, ... }:

let
  # Root-only and outside the flake. Holds `repository` (restic URL),
  # `password` (repository key, also kept in 1Password) and `env`
  # (object-storage credentials). See docs/charon-setup.md.
  secrets = "/var/lib/secrets/restic";
  secretFiles = [ "${secrets}/repository" "${secrets}/password" "${secrets}/env" ];

  site = import ./apps/site.nix;

  # Restores /srv from the latest snapshot. On a fresh install (restore
  # pending) apps have never run, so it proceeds. Otherwise it refuses while
  # /srv holds application files, unless --force, which first moves the
  # current contents aside to /srv.pre-restore-<time> so stale files (such as
  # SQLite WAL files) cannot mix with the restored ones.
  charonRestore = pkgs.writeShellApplication {
    name = "charon-restore";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.systemd ];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        echo "run as root: sudo charon-restore" >&2
        exit 1
      fi
      force=''${1:-}
      if [ ! -e ${site.restorePending} ]; then
        existing=$(find /srv -type f ! -path '/srv/restic-canary/*' -print -quit)
        if [ -n "$existing" ] && [ "$force" != "--force" ]; then
          echo "/srv already has application data ($existing); rerun with --force" >&2
          exit 1
        fi
      fi
      systemctl stop charon-apps.target
      if [ "$force" = "--force" ]; then
        saved=/srv.pre-restore-$(date -u +%Y%m%dT%H%M%SZ)
        mkdir "$saved"
        find /srv -mindepth 1 -maxdepth 1 -exec mv -t "$saved" {} +
        echo "moved the previous /srv contents to $saved"
      fi
      /run/current-system/sw/bin/restic-offsite restore latest --target / --include /srv
      rm -f ${site.restorePending}
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
    "d /var/lib/charon 0755 root root -"
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
    # Stopping every app gives consistent files (SQLite included) without
    # per-app dumps. Cleanup runs after backup, prune and check, even when
    # one of them fails.
    backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop charon-apps.target";
    backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start charon-apps.target";
  };

  # Application services set `partOf` and `wantedBy` to this target, so a
  # restore can stop and restart all of them.
  systemd.targets.charon-apps.wantedBy = [ "multi-user.target" ];
  environment.systemPackages = [ charonRestore ];

  # Skip, rather than fail, until the credentials are installed, and never
  # snapshot a fresh install before its restore (it would become "latest").
  systemd.services.restic-backups-offsite.unitConfig.ConditionPathExists =
    secretFiles ++ [ "!${site.restorePending}" ];
}
