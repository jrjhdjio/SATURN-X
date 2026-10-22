#!/usr/bin/env python3
"""Static compatibility/package checks; this is not an in-game render test."""
import json
import math
import uuid
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parent
PACK=ROOT/'pack'
REF=ROOT.parent/'vanilla-reference/resource_pack'

def require(ok, message):
    if not ok: raise ValueError(message)

def walk(x):
    if isinstance(x,dict):
        for k,v in x.items():
            if isinstance(v,dict) and v and all(key.replace('.','',1).isdigit() for key in v):
                t=sorted((float(key),val) for key,val in v.items())
                require(all(0<=key<=1 for key,val in t),f'Keyframe out of day range: {k}')
                require(len(t)>=2,f'Keyframe lacks endpoints: {k}')
                require(t[0][0]==0 and t[-1][0]==1,f'Keyframe lacks explicit wrap: {k}')
                require(t[0][1]==t[-1][1],f'Keyframe seam: {k}')
            walk(v)
    elif isinstance(x,list):
        for v in x: walk(v)
    elif isinstance(x,float): require(math.isfinite(x),'Non-finite JSON number')

def run():
    files={p.relative_to(PACK).as_posix():json.loads(p.read_text()) for p in PACK.rglob('*.json')}
    m=files['manifest.json']; require(m['format_version']==2,'Manifest version')
    require(m['capabilities']==['pbr'],'Missing PBR capability')
    ids=[m['header']['uuid']]+[v['uuid'] for v in m['modules']]
    for i in ids: uuid.UUID(i)
    require(len(ids)==len(set(ids)),'Duplicate manifest UUID')
    require(m['modules'][0]['type']=='resources','Must be resource pack')
    require(m['header']['version']==m['modules'][0]['version'],'Module version differs from header')
    registry={}; official=set()
    for p in REF.rglob('*.json') if REF.exists() else []:
        d=json.loads(p.read_text())
        for v in d.values():
            if isinstance(v,dict) and isinstance(v.get('description'),dict):
                official.add(v['description'].get('identifier'))
    for path,data in files.items():
        if path=='manifest.json': continue
        require(tuple(map(int,data['format_version'].split('.'))) <= tuple(m['header']['min_engine_version']),f'Engine too old: {path}')
        if path.startswith('biomes/'): continue
        walk(data)
        if path.startswith('subpacks/'): continue
        for v in data.values():
            if isinstance(v,dict) and 'description' in v:
                ident=v['description']['identifier']; require(ident not in registry,f'Duplicate ID: {ident}')
                registry[ident]=path
    biome_count=0
    modified={'minecraft:lighting_identifier','minecraft:atmosphere_identifier',
              'minecraft:color_grading_identifier','minecraft:water_identifier'}
    for path,data in files.items():
        if not path.startswith('biomes/'): continue
        biome_count+=1
        comp=data['minecraft:client_biome']['components']
        for key in modified:
            if key in comp:
                ident=next(iter(comp[key].values()))
                require(ident in registry or ident.startswith('minecraft:'),f'Missing visual resource: {path}: {ident}')
                if official and ident.startswith('minecraft:'):
                    require(ident in official,f'Unknown inherited visual: {path}: {ident}')
        if REF.exists():
            original=json.loads((REF/path).read_text())['minecraft:client_biome']['components']
            require({k:v for k,v in comp.items() if k not in modified}=={k:v for k,v in original.items() if k not in modified},f'Vanilla components changed: {path}')
    require(biome_count==87,f'Expected 87 supported biomes, found {biome_count}')
    water_paths=[x for x in files if x.startswith('water/')]
    for preset in ['','subpacks/cinematic/','subpacks/balanced/','subpacks/calm/']:
        all_caustics=[]; all_enabled=[]
        for path in water_paths:
            w=files[preset+path]['minecraft:water_settings']
            require(w['description']['identifier'] in registry,'Water override identifier')
            waves=w['waves']; require('sampleWidth' not in waves,'Removed sampleWidth')
            ranges={'depth':(0,3),'direction_increment':(0,360),'frequency':(.01,3),
                    'frequency_scaling':(0,2),'mix':(0,1),'octaves':(1,30),
                    'pull':(-1,1),'shape':(1,10),'speed':(.01,10),'speed_scaling':(0,2)}
            for k,(lo,hi) in ranges.items(): require(lo<=waves[k]<=hi,f'Wave range {preset+path}:{k}')
            pc=w['particle_concentrations']
            for k,hi in [('cdom',15),('chlorophyll',10),('suspended_sediment',300)]:
                require(0<=pc[k]<=hi,f'Particle range {path}:{k}')
            all_caustics.append(w['caustics']); all_enabled.append(waves['enabled'])
        require(all(x==all_caustics[0] for x in all_caustics),'Mixed caustics across biomes')
        require(len(set(all_enabled))==1,'Mixed wave enable flags across biomes')
        require(all_enabled[0]==(preset!='subpacks/calm/'),'Wrong preset wave flag')
    grades=[v['minecraft:color_grading_settings'] for p,v in files.items() if p.startswith('color_grading/')]
    require(len({g['tone_mapping']['operator'] for g in grades})==1,'Mixed tonemappers')
    for g in grades:
        cg=g['color_grading']; require(cg['shadows']['shadowsMax']<cg['highlights']['highlightsMin'],'Grade thresholds')
        for band in ['shadows','midtones','highlights']:
            require(all(2<=v<=2.4 for v in cg[band]['gamma']),'Gamma calibration')
    version='.'.join(map(str,m['header']['version']))
    package=ROOT/f'dist/SATURN_X_AURORA_{version}_ULTRA_OCEAN.mcpack'
    with zipfile.ZipFile(package) as z:
        require(z.testzip() is None,'ZIP CRC failure')
        expected={p.relative_to(PACK).as_posix():p.read_bytes() for p in PACK.rglob('*') if p.is_file()}
        require(set(z.namelist())==set(expected),'Archive content mismatch')
        require('manifest.json' in z.namelist(),'Nested root manifest')
        for p,b in expected.items(): require(z.read(p)==b,f'Archive stale: {p}')
    report={'status':'PASS','version':version,'json_files':len(files),'client_biomes':biome_count,
            'custom_visual_identifiers':len(registry),'presets':len(m['subpacks']),'archive_bytes':package.stat().st_size,
            'checks':['JSON parsing','manifest UUIDs','minimum engine versions','visual references',
                      'vanilla component preservation','day-cycle seams','water value ranges',
                      'preset consistency','tonemap consistency','ZIP CRC and exact contents'],
            'minecraft_runtime_tested':False,'android_device_tested':False}
    (ROOT/'VALIDATION.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__': run()
