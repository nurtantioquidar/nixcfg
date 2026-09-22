# Luna Mac mini server

Luna is an Apple silicon Mac mini with 16 GB RAM, a 256 GB SSD, Ethernet,
and a UPS. Its macOS account is `kerberos`. This foundation provides upstream
Nix, nix-darwin, Home Manager, Tailscale, key-only SSH, and Colima/Docker.
It does not install agents or configure desktop automatic login.

## Recovery decision

FileVault and automatic login are deliberately not changed by this flake.
Record the owner's decision before declaring unattended recovery ready.
With FileVault enabled, a cold boot can require someone to unlock the disk.
macOS 26 on Apple silicon supports SSH FileVault unlock, but the mini's own
Tailscale is unavailable at that stage. There is currently no second device
providing a route into its LAN. Do not expose SSH through the internet router
to work around this. A UPS reduces outages but does not solve disk unlocking.

With FileVault disabled, boot services can start without a desktop login;
physical access to the machine becomes a greater data-access risk. Desktop
automation is a separate matter: Chrome, WhatsApp and macOS UI agents need
a GUI session and interactive permissions. Decide that account/session design
when installing agents. Do not give an agent the administrator's credentials.

An intentional shutdown for dust cleaning may require pressing the power
button afterward; restart-after-power-failure does not promise power-on after
a clean shutdown. Shut down normally before unplugging the mini.

## Step 1: Tio at the mini

1. Finish macOS setup with account short name `kerberos`, a strong local
   password, and administrator access for initial setup. Connect Ethernet and
   the UPS. Install available macOS security updates and record the actual
   version with `sw_vers`. Do not assume the fresh install is Sonoma.
2. Install Command Line Tools with `xcode-select --install`, wait for the
   dialog to finish, and verify `xcode-select -p`. Full Xcode is unnecessary
   for this foundation. Homebrew is also unnecessary: Nix supplies these tools.
3. Install the **upstream Nix multi-user installer** from
   [Nix downloads](https://nixos.org/download/), then open a fresh Terminal.
   This profile uses `nix.enable = true`; do not install Determinate Nix and
   disable Nix management as a workaround. Check `nix --version`.
4. Copy this prepared repository, including its new luna files and lock file,
   to `/Users/kerberos/.config/nix`. Use a trusted transfer or clone the revision
   containing the changes. Never copy the laptop's private keys or secrets.
5. Install the public SSH key used by the owner's laptop into
   `/Users/kerberos/.ssh/authorized_keys`. Only the public key belongs here.
   As `kerberos`, create the directory with `mkdir -p ~/.ssh`, set
   `chmod 700 ~/.ssh`, and set `chmod 600 ~/.ssh/authorized_keys` after saving
   the key. Verify `ssh-keygen -lf ~/.ssh/authorized_keys` and compare its
   fingerprint with the owner. Keep this console available throughout setup.
6. Build and activate the foundation locally, using the commands below.
   The first activation checks that the account and a readable public key
   exist before changing system settings. It immediately restricts SSH
   authentication to Tailscale source addresses, so first activation must
   happen at the console rather than over an ordinary LAN SSH connection.

```bash
cd /Users/kerberos/.config/nix
nix --extra-experimental-features nix-command --extra-experimental-features flakes build 'path:/Users/kerberos/.config/nix#darwinConfigurations.luna.system' --out-link result-luna
sudo ./result-luna/sw/bin/darwin-rebuild switch --flake 'path:/Users/kerberos/.config/nix#luna'
```

If Nix reports a pre-existing configuration file conflict, inspect the named
file and preserve it before retrying. Do not delete unrelated configuration.

7. Open a fresh Terminal and run `sudo tailscale up`. Open the authentication
   link and sign in with the owner's account. Enable MFA at the identity
   provider. Do not paste authentication links, passwords or recovery codes
   into the repository. Do not additionally install Tailscale.app: nix-darwin
   manages the CLI daemon on this host.
8. Install Tailscale on the owner's laptop and join the same account/network.
   Record luna's `tailscale ip -4` address. From the laptop test
   `ssh kerberos@<luna-tailscale-ip>` using the owner's key. On luna display
   `sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` and verify the host
   fingerprint on the laptop before accepting it. Never disable host checking.
9. In the Tailscale admin console restrict access to luna's port 22 to the
   owner's identity/devices, removing any default broad allow rule that would
   defeat this restriction. Check device key expiry for luna and deliberately
   configure it for an unattended server; keep account MFA enabled. Test access
   again after policy changes. No port forwarding, Funnel or exit node is needed.

The Nokia Wi-Fi device can continue serving the network unchanged. Its exact
model and routing capabilities are unknown; this setup does not rely on it
running Tailscale.

## Step 2: remote completion

Once the SSH test passes, provide the Tailscale address and confirm the host
fingerprint. Remote continuation requires the controlling laptop to be on
that tailnet and to have the matching SSH key available. Admin operations use
interactive `sudo`; no blanket passwordless sudo is configured.

Run these checks on luna:

```bash
hostname
sw_vers
fdesetup status
tailscale status
sudo /usr/sbin/sshd -t
sudo /usr/sbin/sshd -T -C user=kerberos,host=luna,addr=100.100.100.100
sudo launchctl print system/com.tailscale.tailscaled
sudo launchctl print system/org.nixos.luna-colima
colima status
docker info
docker compose version
docker run --rm hello-world
pmset -g custom
df -h /System/Volumes/Data
```

Verify the effective SSH settings include public-key-only authentication,
no root login and the Tailscale-only `AllowUsers` entries. Check for earlier
macOS SSH drop-ins overriding the intended settings. Confirm an ordinary LAN
SSH login is denied and a Tailscale login succeeds. The application firewall
is enabled, but is not a blanket Tailscale-only filter for all future services.
Bind future container ports to loopback, for example `127.0.0.1:8080:8080`,
and reach them with `ssh -L 8080:127.0.0.1:8080 kerberos@<luna-tailscale-ip>`.
Never expose the Docker daemon over TCP.

Colima runs in the foreground under a system LaunchDaemon as `kerberos`, with
4 CPUs, 6 GiB RAM and a 60 GiB virtual disk. It uses Apple's VZ virtualization
and native ARM containers. First startup requires network access for the VM
image. This is intended to start before GUI login, but must be verified on
luna's actual macOS version. Read `/var/log/luna-colima.error.log` on failure.
Do not run `sudo colima`: that creates a separate root-owned VM.

Before leaving the machine unattended:

1. Reboot with Tio present, leave it at the login screen (after any required
   FileVault unlock), reconnect over Tailscale and rerun `docker info`.
2. Run a temporary container with `--restart unless-stopped`, reboot, and
   verify it resumes. Remove the test container afterward.
3. Test a clean shutdown and physical power-on. Verify the agreed FileVault
   behavior. Confirm restart-after-power-failure separately with a controlled
   test while no valuable workloads exist; avoid interrupting writes.
4. Verify the UPS behavior and reconnect after a brief network interruption.
5. Record what still needs local intervention. Passing Nix evaluation/build
   alone is not evidence that this hardware recovery test passed.

## Maintenance and data

Update and rebuild deliberately; do not schedule unattended macOS reboots
until recovery tests pass. Subsequent system activation:

```bash
sudo darwin-rebuild switch --flake /Users/kerberos/.config/nix#luna
```

For local untracked files use the explicit `path:` form from Step 1; ordinary
Git flakes only include files known to Git. Keep the existing lock file until
an intentional update is needed. If necessary, roll back with
`sudo darwin-rebuild switch --rollback` while console access is available.

Check `docker system df` and free SSD space periodically. Keep at least
30–40 GB free as an operational target. Do not automatically prune Docker
volumes: they may contain the only copy of agent data. Old Nix generations
can be removed deliberately with `sudo nix-collect-garbage --delete-older-than 30d`
after confirming recent generations are healthy; this removes old rollback
points. Container images and logs also consume space outside the Nix store.

Agent workspaces and runtime secrets will live outside the flake, with
credentials scoped to each agent. No API credentials are needed for this
foundation. Keeping files on the mini provides persistence, not a backup
against SSD failure. External USB storage or encrypted off-device storage
can be chosen later; no backup is configured yet.

## References

- [nix-darwin installation](https://github.com/nix-darwin/nix-darwin#installing)
- [Tailscale macOS variants](https://tailscale.com/docs/concepts/macos-variants)
- [Colima foreground mode](https://colima.run/docs/faq/)
- [Apple FileVault security](https://support.apple.com/en-gb/guide/security/sec8447f5049/web)
- [Apple automatic login requirements](https://support.apple.com/en-ie/102316)
