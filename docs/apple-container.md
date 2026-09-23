# Apple container on the MacBooks

Both laptop configurations use Apple's `container` runtime and Opossum for projects with Compose files. The shared Home Manager profile installs the `suruseas/opossum/opossum` cask; its Homebrew dependency installs the `container` formula. The Opossum tap is pinned through `nix-homebrew` in each laptop's Darwin module. This setup requires Apple silicon and macOS 26 or later on each laptop.

## Apply the configuration

On the personal MacBook Pro, use `#styx`; on the company MacBook Air, use `#MAC-YP2JJ9KNWT`:

```sh
sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
# or, on the company MacBook Air:
sudo darwin-rebuild switch --flake /Users/hades/.config/nix#MAC-YP2JJ9KNWT --impure
```

Darwin activation pins the tap; the embedded Home Manager activation installs Opossum and the Apple `container` formula, then removes the previously managed OrbStack cask. The laptop profile also removes its Colima, Docker, Docker Compose, and `act` CLI packages. A standalone `home-manager switch` updates the user profile, but the old commands may remain under `/etc/profiles/per-user/hades/bin` until the Darwin rebuild runs. The Mac mini and WSL keep their separate container configurations.

An already-open zsh session can still have a Starship prompt command pointing at the old `~/.nix-profile/bin/starship`. If the rebuild has finished and that path errors at the prompt, run `exec zsh -l` or open a new terminal. A fresh shell resolves Starship through `/etc/profiles/per-user/hades/bin/starship`.

Start the runtime and register Opossum's DNS domain once on each laptop:

```sh
container system kernel set --recommended
container system start
sudo container system dns create opossum
container run --rm alpine echo hello
```

The Homebrew formula needs the recommended Linux kernel installed before its first unattended start. The DNS registration persists across reboots. Run `container system start` again if the runtime is stopped. If the Homebrew `container` formula is upgraded, restart the runtime afterward; the formula stops an older service during its upgrade.

## Use a Compose project

From the directory containing `compose.yaml` or `docker-compose.yml`:

```sh
opossum config
opossum up
opossum ps
opossum logs --follow
opossum down
```

`opossum config` reports fields it ignores. `opossum up` builds images with Apple's builder when a service has `build:`. If a database bind mount cannot be owned from inside the container, `opossum up --from-docker-compose` can generate a `compose.opossum.yaml` override that uses a named volume. That flag also tries to import images from a running Docker daemon, so it is useful only while a Docker runtime is still available. Inspect the generated override before relying on it: changing a bind mount to a named volume does not copy existing data.

Apple's runtime has no Docker socket or Docker API. Tools that require `/var/run/docker.sock`, including `act` and Docker based test harnesses, need a different workflow. A named volume can be attached to only one running container at a time; use a bind mount for data shared by multiple services. Opossum supports a subset of Compose, so check each project's config and behavior before assuming that a successful `up` means the application works.

Sources: [Apple container](https://github.com/apple/container), [Opossum](https://github.com/suruseas/opossum), [Opossum compatibility](https://github.com/suruseas/opossum/blob/main/docs/compatibility.md), and [Opossum troubleshooting](https://github.com/suruseas/opossum/blob/main/docs/troubleshooting.md).
