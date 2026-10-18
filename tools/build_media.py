"""Rebuild the embedded shared media module without changing feature code.

Run: python tools/build_media.py --saturn-only
Omit --saturn-only to rebuild other legacy BM scripts as well.
Edit shared/locales.json for translations and shared/SATURN_X_MEDIA.lua for UI/audio.
No third-party Python packages are required.
"""
from pathlib import Path
import json
import re
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--saturn-only', action='store_true')
args = parser.parse_args()

ROOT = Path(__file__).resolve().parent.parent
MODULE = ROOT / 'shared/SATURN_X_MEDIA.lua'
START = '-- BEGIN SATURN_X_SHARED_MEDIA 1.0.0'
END = '-- END SATURN_X_SHARED_MEDIA'
locales = json.loads((ROOT / 'shared/locales.json').read_text())

def quote(value):
    return json.dumps(value, ensure_ascii=False)

rows = ['local translations = {']
for source, values in locales.items():
    rows.append('    [' + quote(source) + ']={en=' + quote(values['en']) +
                ',zh=' + quote(values['zh']) + '},')
rows.append('}')
module = MODULE.read_text()
for name in ('Motion', 'Orbit'):
    start = 'local Install' + name + ' = (function()\n'
    a = module.index(start) + len(start)
    b = module.index('\nend)()', a)
    module = module[:a] + (ROOT / ('shared/SATURN_X_' + name.upper() + '.lua')).read_text().rstrip() + module[b:]
a = module.index('-- BEGIN_LOCALES') + len('-- BEGIN_LOCALES')
b = module.index('-- END_LOCALES', a)
module = module[:a] + '\n' + '\n'.join(rows) + '\n' + module[b:]
MODULE.write_text(module)
embedded = START + '\nlocal SXMedia = (function()\n' + module + '\nend)()\n' + END
count = 0
for path in sorted(ROOT.glob('SATURN_X*.lua' if args.saturn_only else '*.lua')):
    source = path.read_text()
    if START not in source:
        continue
    a, b = source.index(START), source.index(END) + len(END)
    path.write_text(source[:a] + embedded + source[b:])
    count += 1
print(f'Rebuilt shared media in {count} scripts; {len(locales)} translation keys.')
