#!/usr/bin/env python3
"""Build/verify an update without changing Android identity or using a debug key."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "pl.elklient.kalendarzkierowcy.beta"


def run(command, capture=False):
    return subprocess.run(command, cwd=ROOT, check=True, text=True,
                          stdout=subprocess.PIPE if capture else None).stdout


def verify(apk, apksigner, aapt, release):
    report = run([apksigner, "verify", "--print-certs", str(apk)], True)
    signer = re.search(r"certificate SHA-256 digest: ([a-f0-9]+)", report)
    expected = (ROOT / "beta/android-signing-cert.sha256").read_text().strip()
    if not signer or signer.group(1) != expected:
        raise ValueError("Nieprawidłowy podpis APK. Użyj oryginalnego klucza bety.")
    badging = run([aapt, "dump", "badging", str(apk)], True)
    if f"name='{PACKAGE}'" not in badging or f"versionCode='{release['version_code']}'" not in badging or f"versionName='{release['version_name']}'" not in badging:
        raise ValueError("Identyfikator lub wersja APK nie pasuje do wydania.")
    if "application-debuggable" in badging:
        raise ValueError("Nie publikuj wersji debug.")
    with zipfile.ZipFile(apk) as z:
        entries = z.namelist()
        if "assets/beta/release.json" not in entries or json.loads(z.read("assets/beta/release.json")) != release:
            raise ValueError("APK ma nieaktualną konfigurację bety.")
        if any(n.startswith(("assets/apps/", "assets/tests/", "assets/tools/")) for n in entries):
            raise ValueError("APK zawiera pliki spoza aplikacji kierowcy.")
        if b"driver_beta" not in z.read("assets/project.binary"):
            raise ValueError("Brak obowiązkowej aktywacji beta w APK.")
    return expected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--apksigner", default="apksigner")
    parser.add_argument("--aapt", default="aapt")
    parser.add_argument("--version-code", type=int)
    parser.add_argument("--version-name")
    parser.add_argument("--verify-only", type=Path)
    args = parser.parse_args()
    release_file = ROOT / "beta/release.json"
    release = json.loads(release_file.read_text())
    if args.version_code is not None:
        if args.version_code < release["version_code"] or args.version_code < 1:
            raise ValueError("Nie zmniejszaj numeru wersji.")
        release["version_code"] = args.version_code
        if not args.version_name:
            raise ValueError("Podaj również --version-name.")
        if not re.fullmatch(r"[0-9][a-zA-Z0-9. -]{0,39}", args.version_name):
            raise ValueError("Nieprawidłowa nazwa wersji.")
        release["version_name"] = args.version_name
        release_file.write_text(json.dumps(release, ensure_ascii=False, indent=2) + "\n")
        presets = ROOT / "export_presets.cfg"
        source = presets.read_text()
        source = re.sub(r"(?m)^version/code=.*$", f"version/code={args.version_code}", source)
        source = re.sub(r"(?m)^version/name=.*$", f'version/name="{args.version_name}"', source)
        presets.write_text(source)
    if release["package"] != PACKAGE:
        raise ValueError("Nie zmieniaj identyfikatora aplikacji podczas aktualizacji.")
    output = ROOT / "build"
    output.mkdir(exist_ok=True)
    apk = args.verify_only or output / f"Kalendarz-Kierowcy-Beta-{release['version_code']}.apk"
    if not args.verify_only:
        for name in ("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"):
            if not os.environ.get(name):
                raise ValueError(f"Ustaw {name}; nie zapisuj hasła w repozytorium.")
        os.environ.setdefault("GODOT_ANDROID_KEYSTORE_RELEASE_USER", "driver-beta")
        run([args.godot, "--headless", "--path", str(ROOT), "--editor", "--import", "--export-release", "Android Beta", str(apk)])
    certificate = verify(apk, args.apksigner, args.aapt, release)
    metadata = dict(release, sha256=hashlib.file_digest(apk.open("rb"), "sha256").hexdigest(),
                    size=apk.stat().st_size, signing_certificate_sha256=certificate,
                    source_commit=run(["git", "rev-parse", "HEAD"], True).strip())
    manifest = apk.with_suffix(".release.json")
    manifest.write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"Gotowe: {apk}\nPlik wydania: {manifest}")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, subprocess.CalledProcessError) as error:
        print(f"Błąd: {error}", file=sys.stderr)
        sys.exit(1)
