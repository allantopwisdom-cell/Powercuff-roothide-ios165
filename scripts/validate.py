#!/usr/bin/env python3
"""Validate packaging invariants and inspect a built deb without installing it."""
import argparse
import io
import pathlib
import plistlib
import subprocess
import tarfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--packages', type=pathlib.Path)
args = parser.parse_args()
control = dict(line.split(': ', 1) for line in (ROOT / 'control').read_text().splitlines() if ': ' in line)
assert control['Architecture'] == 'iphoneos-arm64e', 'Expected a native roothide package'
for path in ROOT.rglob('*.plist'):
    if '.theos' not in path.parts:
        plistlib.loads(path.read_bytes())
filter_plist = plistlib.loads((ROOT / 'Powercuff.plist').read_bytes())
assert filter_plist['Filter']['Executables'] == ['thermalmonitord', 'SpringBoard']
source = (ROOT / 'Powercuff.x').read_text()
assert '/var/jb' not in source, 'Do not hardcode the jailbreak root'
assert 'kCFPreferencesAnyHost' in source
prefs = plistlib.loads((ROOT / 'layout/Library/PreferenceLoader/Preferences/Powercuff/Powercuff.plist').read_bytes())
mode = next(item for item in prefs['items'] if item.get('key') == 'PowerMode')
assert mode['validValues'] == [0, 1, 2, 3, 4]
assert mode['default'] == 0
if args.packages:
    packages = list(args.packages.glob('*.deb'))
    assert packages, 'No deb was produced'
    for package in packages:
        data = package.read_bytes()
        assert data.startswith(b'!<arch>\n'), 'Not a Debian ar archive'
        offset = 8
        members = {}
        while offset + 60 <= len(data):
            header = data[offset:offset + 60]
            assert header[58:60] == b'`\n'
            name = header[:16].decode().strip().rstrip('/')
            size = int(header[48:58].decode().strip())
            members[name] = data[offset + 60:offset + 60 + size]
            offset += 60 + size + (size % 2)
        payload_key = next(k for k in members if k.startswith('data.tar'))
        control_key = next(k for k in members if k.startswith('control.tar'))
        with tarfile.open(fileobj=io.BytesIO(members[control_key]), mode='r:*') as archive:
            member = next(m for m in archive.getmembers() if m.name.lstrip('./') == 'control')
            packaged_control = archive.extractfile(member).read().decode()
            assert 'Architecture: iphoneos-arm64e' in packaged_control
        with tarfile.open(fileobj=io.BytesIO(members[payload_key]), mode='r:*') as archive:
            files = {m.name.lstrip('./'): m for m in archive.getmembers() if m.isfile()}
            dylib = 'Library/MobileSubstrate/DynamicLibraries/Powercuff.dylib'
            assert dylib in files, 'Unexpected rootless payload layout'
            assert dylib.replace('.dylib', '.plist') in files
            assert 'Library/PreferenceLoader/Preferences/Powercuff/Powercuff.plist' in files
            assert not any(p.startswith('var/jb/') for p in files)
            binary = archive.extractfile(files[dylib]).read()
            assert binary[:4] == b'\xcf\xfa\xed\xfe', 'Expected thin 64-bit Mach-O'
            assert int.from_bytes(binary[4:8], 'little') == 0x100000c, 'Expected ARM64'
            subtype = int.from_bytes(binary[8:12], 'little')
            assert subtype & 0xffffff == 2, 'Expected arm64e'
            assert subtype & 0x80000000, 'Expected the iOS 14+ arm64e ABI'
            print(f'{package.name}: roothide layout, arm64e ABI v{subtype >> 24 & 0x7f}, {len(binary)} bytes')
print('Source/package checks passed')
