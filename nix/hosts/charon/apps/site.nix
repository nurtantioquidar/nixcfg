# Values shared by charon's application modules (a plain attribute set).
{
  # MagicDNS name; `tailscale serve` gets its HTTPS certificate for it.
  tailnetHost = "charon.tail8801a4.ts.net";

  # Created by provision.sh before first boot and removed by charon-restore.
  # Apps and backups do not start while it exists, so a fresh install neither
  # writes empty state over the restore nor backs it up as "latest".
  restorePending = "/var/lib/charon/restore-pending";
}
