#!/usr/bin/env python3
"""Export the same Godot calendar as a single-threaded, installable web beta.

Static output goes to build/iphone; a compressed, immutable WASM engine is
kept separately for R2 (Workers static assets have a per-file size limit).
Never change the public /iphone/index.html URL or the Godot application name.
"""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--site', type=Path, help='Copy completed static output into this existing Site checkout')
    args = parser.parse_args()
    (ROOT / 'build').mkdir(exist_ok=True)
    (ROOT / 'build/.gdignore').touch()
    output = ROOT / 'build/iphone'
    output.mkdir(parents=True, exist_ok=True)
    subprocess.run([args.godot, '--headless', '--path', str(ROOT), '--export-release', 'iPhone Web Beta', str(output / 'index.html')], check=True)
    wasm = output / 'index.wasm'
    packed = gzip.compress(wasm.read_bytes(), compresslevel=9, mtime=0)
    digest = hashlib.sha256(packed).hexdigest()
    engine_file = ROOT / 'build' / (digest + '.wasm.gz')
    engine_file.write_bytes(packed)
    asset_url = '/api/web-assets/' + digest + '/index.wasm'
    # Engine.load() adds .wasm. mainPack stays fixed so the filesystem remains
    # independent from the engine binary's content hash.
    html = (output / 'index.html').read_text()
    match = re.search(r'const config = (\{.*?\});', html)
    if not match:
        raise SystemExit('Godot shell configuration not found')
    config = json.loads(match.group(1))
    config['executable'] = asset_url.removesuffix('.wasm')
    config['mainPack'] = 'index.pck'
    config['experimentalVK'] = True
    config['serviceWorker'] = ''  # Our worker only activates between sessions.
    html = html[:match.start(1)] + json.dumps(config, ensure_ascii=False) + html[match.end(1):]
    (output / 'index.html').write_text(html)
    wasm.unlink()
    for generated_import in output.glob('*.import'):
        generated_import.unlink()
    (output / 'manifest.webmanifest').write_text(json.dumps({
        'id': '/iphone/', 'name': 'Kalendarz Kierowcy Beta', 'short_name': 'Kalendarz',
        'lang': 'pl', 'start_url': '/iphone/index.html', 'scope': '/iphone/',
        'display': 'standalone', 'orientation': 'portrait',
        'background_color': '#101a28', 'theme_color': '#101a28',
        'icons': [{'src': 'index.apple-touch-icon.png', 'sizes': '180x180', 'type': 'image/png'}],
    }, ensure_ascii=False, indent=2))
    files = sorted(path.name for path in output.iterdir() if path.is_file() and path.name != 'service-worker.js')
    build_hash = hashlib.sha256(b''.join((output / name).read_bytes() for name in files) + packed).hexdigest()[:20]
    engine_files = [asset_url, asset_url.replace('.wasm', '.audio.worklet.js'), asset_url.replace('.wasm', '.audio.position.worklet.js')]
    sw = (ROOT / 'web/service-worker.js').read_text().replace('__BUILD__', build_hash).replace('__FILES__', json.dumps(files + engine_files))
    (output / 'service-worker.js').write_text(sw)
    metadata = {'build': build_hash, 'engine_sha256': digest, 'engine_file': str(engine_file), 'engine_url': asset_url, 'static_directory': str(output)}
    (ROOT / 'build/iphone-release.json').write_text(json.dumps(metadata, indent=2))
    if args.site:
        if not (args.site / '.openai/hosting.json').is_file():
            raise SystemExit('--site must be the existing registered beta portal')
        for generated_import in (args.site / 'public/iphone').glob('*.import'):
            generated_import.unlink()
        shutil.copytree(output, args.site / 'public/iphone', dirs_exist_ok=True)
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
