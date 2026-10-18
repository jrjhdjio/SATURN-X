"""Rebuild the embedded shared media module without changing feature code.

Run: python tools/build_media.py
Edit shared/locales.json for translations and shared/SATURN_X_MEDIA.lua for UI/audio.
No third-party Python packages are required.
"""
from pathlib import Path
import json
import re

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
a = module.index('-- BEGIN_LOCALES') + len('-- BEGIN_LOCALES')
b = module.index('-- END_LOCALES', a)
module = module[:a] + '\n' + '\n'.join(rows) + '\n' + module[b:]
MODULE.write_text(module)
embedded = START + '\nlocal SXMedia = (function()\n' + module + '\nend)()\n' + END
count = 0
for path in sorted(ROOT.glob('*.lua')):
    source = path.read_text()
    if START not in source:
        continue
    a, b = source.index(START), source.index(END) + len(END)
    path.write_text(source[:a] + embedded + source[b:])
    count += 1
print(f'Rebuilt shared media in {count} scripts; {len(locales)} translation keys.')
