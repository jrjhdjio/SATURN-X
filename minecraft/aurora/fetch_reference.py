#!/usr/bin/env python3
"""Fetch the pinned official references and verify their SHA-256 hashes."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
from urllib.request import urlopen

root=Path(__file__).resolve().parent
receipt=json.loads((root/'UPSTREAM.json').read_text())
destination=root.parent/'vanilla-reference'
commit=receipt['commit']
def fetch(item):
    path=item['path']
    with urlopen(f'https://raw.githubusercontent.com/Mojang/bedrock-samples/{commit}/{path}',timeout=60) as response:
        data=response.read()
    if hashlib.sha256(data).hexdigest()!=item['sha256']:
        raise ValueError(f'Upstream hash mismatch: {path}')
    out=destination/path
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_bytes(data)
    return path
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    downloaded=list(pool.map(fetch,receipt['files']))
(destination/'UPSTREAM.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(f'Verified {len(downloaded)} official reference files at {commit}')
