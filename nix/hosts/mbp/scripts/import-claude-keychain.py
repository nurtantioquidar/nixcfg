#!/usr/bin/env python3
"""Import the assisted migration's Claude credential from the MBP console."""

import ctypes as c
import getpass
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import time


def main():
    if platform.system() != "Darwin" or os.getuid() != 501 or getpass.getuser() != "hades":
        raise SystemExit("Run this locally as hades (UID 501) on styx.")
    if len(sys.argv) != 2:
        raise SystemExit("Usage: import-claude-keychain.py <private-credential-file>")
    source = Path(sys.argv[1]).expanduser().resolve()
    stat = source.stat()
    if stat.st_uid != os.getuid() or stat.st_mode & 0o077:
        raise SystemExit("Credential file must be owned by hades and private (mode 600).")
    data = source.read_bytes()
    record = json.loads(data)
    if not record.get("claudeAiOauth", {}).get("accessToken"):
        raise SystemExit("Expected a Claude OAuth credential record.")

    # Keep tokens in memory, never in command arguments or printed output.
    security = c.CDLL("/System/Library/Frameworks/Security.framework/Security")
    core = c.CDLL("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
    pointer, uint = c.c_void_p, c.c_uint32

    class Attribute(c.Structure):
        _fields_ = [("tag", uint), ("length", uint), ("data", pointer)]

    class AttributeList(c.Structure):
        _fields_ = [("count", uint), ("attributes", c.POINTER(Attribute))]

    core.CFStringCreateWithCString.argtypes = [pointer, c.c_char_p, uint]
    core.CFStringCreateWithCString.restype = pointer
    core.CFArrayCreate.argtypes = [pointer, c.POINTER(pointer), c.c_long, pointer]
    core.CFArrayCreate.restype = pointer
    security.SecTrustedApplicationCreateFromPath.argtypes = [c.c_char_p, c.POINTER(pointer)]
    security.SecAccessCreate.argtypes = [pointer, pointer, c.POINTER(pointer)]
    security.SecKeychainItemCreateFromContent.argtypes = [
        uint, c.POINTER(AttributeList), uint, pointer, pointer, pointer, c.POINTER(pointer)
    ]
    security.SecKeychainCopyDefault.argtypes = [c.POINTER(pointer)]
    security.SecKeychainGetStatus.argtypes = [pointer, c.POINTER(uint)]
    security.SecKeychainFindGenericPassword.argtypes = [
        pointer, uint, c.c_char_p, uint, c.c_char_p, c.POINTER(uint), c.POINTER(pointer), c.POINTER(pointer)
    ]
    security.SecKeychainItemModifyContent.argtypes = [pointer, c.POINTER(AttributeList), uint, pointer]
    for name in ("SecTrustedApplicationCreateFromPath", "SecAccessCreate", "SecKeychainItemCreateFromContent"):
        getattr(security, name).restype = c.c_int32
    for name in ("SecKeychainCopyDefault", "SecKeychainGetStatus", "SecKeychainFindGenericPassword", "SecKeychainItemModifyContent"):
        getattr(security, name).restype = c.c_int32

    keychain, flags = pointer(), uint()
    status = security.SecKeychainCopyDefault(c.byref(keychain))
    if not status:
        status = security.SecKeychainGetStatus(keychain, c.byref(flags))
    if status:
        raise SystemExit(f"Could not inspect the default Keychain (OSStatus {status}).")
    if not flags.value & 1:
        if not sys.stdin.isatty():
            raise SystemExit("Login Keychain is locked. Run this in the MBP's local Terminal.")
        print("Unlocking your login Keychain. Enter its password at the local prompt.", flush=True)
        # macOS reads the password at the terminal; the helper never receives it.
        if subprocess.run(["/usr/bin/security", "unlock-keychain"]).returncode:
            raise SystemExit("Keychain unlock failed; no credential was replaced.")

    trusted = pointer()
    status = security.SecTrustedApplicationCreateFromPath(b"/usr/bin/security", c.byref(trusted))
    if status:
        raise SystemExit(f"Could not configure the credential reader (OSStatus {status}).")
    apps = (pointer * 1)(trusted.value)
    array = core.CFArrayCreate(None, apps, 1, None)
    description = core.CFStringCreateWithCString(None, b"Claude Code-credentials", 0x08000100)
    access = pointer()
    status = security.SecAccessCreate(description, array, c.byref(access))
    if status:
        raise SystemExit(f"Could not configure Keychain access (OSStatus {status}).")

    service = c.create_string_buffer(b"Claude Code-credentials")
    account = c.create_string_buffer(b"hades")
    secret = c.create_string_buffer(data)
    attributes = (Attribute * 2)(
        Attribute(0x73766365, len(service.value), c.cast(service, pointer)),
        Attribute(0x61636374, len(account.value), c.cast(account, pointer)),
    )
    listing, item = AttributeList(2, attributes), pointer()
    status = security.SecKeychainFindGenericPassword(
        keychain, len(service.value), service.value, len(account.value), account.value,
        None, None, c.byref(item)
    )
    if status == 0:
        existing = subprocess.run(
            ["/usr/bin/security", "find-generic-password", "-s", "Claude Code-credentials", "-a", "hades", "-w"],
            capture_output=True, timeout=30,
        )
        if existing.returncode:
            raise SystemExit("Cannot back up the existing credential. Unlock the login Keychain and allow security to read this item, then retry. No credential was replaced.")
        old_data = existing.stdout.rstrip(b"\n")
        if old_data == data:
            print("Current Claude credential is already imported.")
        else:
            backup = source.parent / f"claude-before-repair-{time.time_ns()}.secret"
            fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "wb") as stream:
                stream.write(old_data)
            status = security.SecKeychainItemModifyContent(item, None, len(data), c.cast(secret, pointer))
            if status:
                raise SystemExit(f"Credential update failed (OSStatus {status}); existing credential backed up at {backup}.")
            print(f"Previous Claude credential backed up privately at {backup}.")
            print("Current Claude credential restored.")
    elif status == -25300:
        status = security.SecKeychainItemCreateFromContent(
            0x67656E70, c.byref(listing), len(data), c.cast(secret, pointer), keychain, access, c.byref(item)
        )
        if status == 0:
            print("Claude credential imported.")
    if status == -25308:
        raise SystemExit("Keychain requires local interaction. Unlock your login Keychain and run this in the MBP's Terminal.")
    if status != 0:
        raise SystemExit(f"Keychain import failed (OSStatus {status}).")

    # Auth status contains no token values; display only the login result.
    executable = Path.home() / ".local/bin/claude"
    result = subprocess.run([str(executable), "auth", "status"], capture_output=True, text=True, timeout=30)
    try:
        logged_in = json.loads(result.stdout).get("loggedIn", False)
    except ValueError:
        logged_in = False
    print(f"Claude logged in: {logged_in}")
    if not logged_in:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
