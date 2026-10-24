#!/usr/bin/env python3
"""Snapshot laptop user state outside the flake, without printing credentials."""

import argparse
import json
import os
from pathlib import Path
import shutil
import sqlite3
import stat
import tempfile
from contextlib import closing
from datetime import datetime, timezone


HOME_PATHS = [
    ".ssh", ".config", ".claude", ".claude.json", ".codex", ".agents",
    ".aws", ".azure", ".kube", ".oci", ".gnupg", ".netrc",
    ".git-credentials", ".npmrc", ".pypirc", ".docker/config.json",
    ".zsh_history", ".bash_history", ".local/share/fish/fish_history",
    ".local/share/opencode", ".local/share/zellij",
    "Library/Application Support/Claude/claude-code-sessions",
]
# These contain machine identity, processes, installed binaries, or rebuildable state.
SKIP = {
    ".ssh/agent", ".ssh/authorized_keys", ".ssh/authorized_keys.jcorig",
    ".config/nix", ".config/nix-airdrop-backup", ".config/1Password",
    ".config/op", ".config/homebrew", ".config/herdr/session.json",
    ".codex/packages", ".codex/tmp", ".codex/.tmp", ".codex/cache",
    ".codex/ipc", ".codex/app-server-control", ".codex/app-server-daemon",
    ".codex/computer-use", ".codex/node_repl", ".codex/log",
    ".codex/logs_2.sqlite", ".codex/thread-writer-locks",
    ".codex/mcp-oauth-locks", ".codex/tui-thread-reference-capabilities",
    ".codex/.sqlite-maintenance.lock", ".config/herdr/.plugins.lock",
    ".claude/local", ".claude/cache", ".claude/downloads",
    ".claude/session-env", ".claude/sessions", ".claude/telemetry",
}


def snapshot(source_home, repo, output):
    output.mkdir(mode=0o700, parents=False, exist_ok=False)
    payload = output / "home"
    payload.mkdir(mode=0o700)
    copied = []
    omitted = []
    databases = []

    def copy(source, destination, relative, repository=False):
        if relative in SKIP and not repository:
            omitted.append(relative)
            return
        if repository and source.name in {".direnv", "result"}:
            omitted.append(relative)
            return
        mode = source.lstat().st_mode
        if stat.S_ISLNK(mode):
            target = os.readlink(source)
            if target.startswith(("/nix/", "/etc/profiles/", "/private/tmp/", "/tmp/")):
                omitted.append(relative + " (managed/runtime symlink)")
                return
            destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            destination.symlink_to(target)
            copied.append(relative)
        elif stat.S_ISDIR(mode):
            destination.mkdir(parents=True, exist_ok=True, mode=0o700)
            for child in sorted(source.iterdir()):
                copy(child, destination / child.name, relative + "/" + child.name, repository)
        elif stat.S_ISREG(mode):
            if source.name.endswith(("-wal", "-shm", ".sock")) or source.name.startswith("logs_2.sqlite"):
                omitted.append(relative)
                return
            destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            with source.open("rb") as handle:
                sqlite_header = handle.read(16) == b"SQLite format 3\x00"
            if sqlite_header:
                # Online backup incorporates committed WAL entries. Do not use
                # immutable=1: that ignores the WAL of a running app.
                with closing(sqlite3.connect(source.as_uri() + "?mode=ro", uri=True, timeout=30)) as src:
                    with closing(sqlite3.connect(destination)) as dst:
                        src.backup(dst)
                        dst.execute("PRAGMA journal_mode=DELETE")
                        if dst.execute("PRAGMA quick_check").fetchone()[0] != "ok":
                            raise RuntimeError("Database integrity check failed: " + relative)
                databases.append(relative)
            else:
                shutil.copyfile(source, destination)
            destination.chmod(0o700 if mode & 0o111 else 0o600)
            copied.append(relative)
        else:
            omitted.append(relative + " (socket or special file)")

    for relative in HOME_PATHS:
        source = source_home / relative
        if source.exists() or source.is_symlink():
            copy(source, payload / relative, relative)
    copy(repo, payload / ".config/nix", ".config/nix", repository=True)
    if not (payload / ".config/nix/flake.lock").is_file():
        raise RuntimeError("Repository snapshot is missing flake.lock")
    manifest = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "source_home": str(source_home), "source_uid": os.getuid(),
        "target_home": "/Users/hades", "target_uid": 501,
        "files": copied, "sqlite_backups": databases, "omitted": omitted,
        "notes": [
            "Contains secrets; transfer only to your MBP through SSH or AirDrop.",
            "Keychain and 1Password vaults are not exported; sign in on the MBP.",
            "Project working trees and their .env files are not included.",
            "Active agent processes are not portable; resume saved conversations.",
            "Snapshot taken while apps may be running; refresh after they are idle.",
        ],
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (output / "manifest.json").chmod(0o600)
    (output / "READY").touch(mode=0o600)
    return len(copied), len(databases)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="New private directory outside the repository")
    args = parser.parse_args()
    os.umask(0o077)
    repo = Path(__file__).resolve().parents[4]
    output = (args.output or Path(tempfile.gettempdir()) / (
        "styx-migration-" + datetime.now().strftime("%Y%m%d-%H%M%S")
    )).resolve()
    if output.is_relative_to(repo) or repo.is_relative_to(output):
        parser.error("Output must be outside the repository")
    if any(output.is_relative_to(Path.home() / relative) for relative in HOME_PATHS):
        parser.error("Output must be outside the user-state paths being copied")
    count, database_count = snapshot(Path.home(), repo, output)
    print(f"Ready: {output}\nCopied {count} files; verified {database_count} SQLite snapshots.")
    print("This directory contains secrets. The READY marker indicates successful completion.")


if __name__ == "__main__":
    main()
