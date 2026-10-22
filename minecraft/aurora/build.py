#!/usr/bin/env python3
"""Build SATURN X AURORA from official client biomes and authored VV settings.

Input: ../vanilla-reference, pinned in UPSTREAM.json. No runtime code or mods.
Rebuild with the Python standard library; pack_icon.png is a committed asset.
"""
import copy
import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REF = ROOT.parent / 'vanilla-reference'
PACK = ROOT / 'pack'
OUT = ROOT / 'dist'
NS = 'saturn_aurora'

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def obj(kind, ident, version, **kw):
    return {'format_version': version, f'minecraft:{kind}_settings':
            {'description': {'identifier': f'{NS}:{ident}'}, **kw}}

def curve(*pairs):
    return {str(t): v for t, v in pairs}

def make_lighting(name, factor=1, sky=.90, ambient=.028):
    # Minecraft VV keys use noon=0; sunset=.25; midnight=.5; sunrise=.75.
    # Stay close to the shipped 26.50 sample's 100-lux noon calibration.
    lux = curve((0.0,112),(.17,64),(.23,24),(.25,15),(.282,1.0),(.292,0),
                (.5,0),(.709,0),(.719,1.0),(.75,17),(.82,58),(1.0,112))
    lux = {k:round(v * factor, 4) for k,v in lux.items()}
    color = curve((0.0,'#FFF6E8'),(.17,'#FFEACD'),(.25,'#FFC18B'),(.30,'#E9B1B7'),
                  (.35,'#CDD9F9'),(.5,'#CDD9F9'),(.65,'#CDD9F9'),(.70,'#F2B9B0'),
                  (.75,'#FFD0A0'),(.84,'#FFF0D7'),(1.0,'#FFF6E8'))
    return obj('lighting',name,'1.21.80',
        directional_lights={'orbital':{'sun':{'illuminance':lux,'color':color},
            'moon':{'illuminance':curve((0.0,0),(.20,0),(.23,.40),(.735,.40),(.75,0),(1.0,0)),
                    'color':'#C2D6FF'},'orbital_offset_degrees':0.0},
            'flash':{'illuminance':4.0,'color':'#CFB6FF'}},
        emissive={'desaturation':.14},ambient={'illuminance':ambient,'color':'#D7E3FF'},
        sky={'intensity':sky})

def make_atmos(name, family):
    day = {'temperate':'#458CC7','tropical':'#378FC3','arid':'#619BC7',
           'alpine':'#4D8DBD','cherry':'#5D94C7','mystic':'#5D7A9D'}[family]
    horizon = {'temperate':'#C2E0EA','tropical':'#B6E4DA','arid':'#E5D7B9',
               'alpine':'#C9E5EF','cherry':'#E5D6E7','mystic':'#ABBCC9'}[family]
    return obj('atmosphere',name,'1.21.40',
        horizon_blend_stops={'min':0.0,'start':curve((0.0,.75),(.25,.42),(.35,.28),(.65,.28),(.75,.32),(1.0,.75)),
                             'mie_start':.55,'max':.25},
        rayleigh_strength=curve((0.0,9.0),(.20,7.0),(.25,4.8),(.34,4.7),
                                (.5,5.0),(.66,4.7),(.75,4.8),(.84,7.0),(1.0,9.0)),
        sun_mie_strength=curve((0.0,.03),(.18,.18),(.25,.95),(.31,.22),
                               (.4,0),(.6,0),(.7,.22),(.75,.85),(.84,.18),(1.0,.03)),
        moon_mie_strength=curve((0.0,0),(.28,0),(.35,.035),(.5,.06),(.65,.035),(.72,0),(1.0,0)),
        sun_glare_shape=.06,
        sky_zenith_color=curve((0.0,day),(.18,day),(.25,'#4D5C95'),(.33,'#252B54'),
                               (.5,'#101C38'),(.66,'#252B54'),(.75,'#647AA5'),(.85,day),(1.0,day)),
        sky_horizon_color=curve((0.0,horizon),(.16,horizon),(.25,'#F7A278'),
                                (.30,'#BE7E9C'),(.36,'#605C89'),(.5,'#435A83'),
                                (.64,'#605C89'),(.70,'#CF93A4'),(.75,'#F5C098'),
                                (.86,horizon),(1.0,horizon)))

def make_grade(name, saturation=1.06, temperature=6500, contrast=1.045):
    def band(gain, sat, con, gamma=2.2):
        return {'contrast':[con]*3,'gain':gain,'gamma':[gamma]*3,
                'offset':[0.0]*3,'saturation':[sat]*3}
    shadow=band([.99,1.0,1.025],1.0,1.015,2.23)
    shadow.update(enabled=True,shadowsMax=.55)
    highlight=band([1.015,1.0,.985],1.015,1.01)
    highlight.update(enabled=True,highlightsMin=1.8)
    return obj('color_grading',name,'1.21.90',
        color_grading={'midtones':band([1.0,1.0,1.0],saturation,contrast),
            'shadows':shadow,'highlights':highlight,
            'temperature':{'enabled':True,'temperature':temperature,'type':'color_temperature'}},
        tone_mapping={'operator':'aces'})

WATER = {
    # CDOM, chlorophyll, sediment, wave depth, frequency, speed
    'clear':(.06,.12,.08,.20,.65,.85),
    'ocean':(.025,.18,.08,.44,.58,1.05),
    'tropical':(.015,.08,.035,.32,.68,.95),
    'deep':(.04,.35,.12,.50,.54,1.10),
    'river':(.30,.22,.35,.16,.85,.90),
    'alpine':(.02,.08,.035,.15,.75,.70),
    'swamp':(1.5,1.15,1.0,.10,.85,.55),
}

def make_water(name, values, calm=False):
    cdom, chl, sediment, depth, frequency, speed = values
    return obj('water',f'water_{name}','1.21.120',
        particle_concentrations={'cdom':cdom,'chlorophyll':chl,'suspended_sediment':sediment},
        waves={'enabled':not calm,'depth':depth,'direction_increment':80.0,'frequency':frequency,
               'frequency_scaling':1.20,'mix':.22,'octaves':12,'pull':.32,
               'shape':1.5,'speed':speed,'speed_scaling':1.03},
        caustics={'enabled':True,'frame_length':.055,'power':2,'scale':.55})

def group(name):
    if name in {'hell','crimson_forest','warped_forest','soulsand_valley','basalt_deltas'}:
        return 'nether'
    if name == 'the_end': return 'end'
    if any(s in name for s in ['deep_dark','dripstone','lush_caves','sulfur_caves']): return 'cave'
    if 'cherry' in name: return 'cherry'
    if any(s in name for s in ['swamp','pale_garden','roofed','mushroom']): return 'mystic'
    if any(s in name for s in ['cold','frozen','ice','snow','grove','jagged','stony_peaks']): return 'alpine'
    if any(s in name for s in ['jungle','warm_ocean','lukewarm_ocean','mangrove']): return 'tropical'
    if any(s in name for s in ['desert','mesa','savanna','badlands']): return 'arid'
    return 'temperate'

def water_group(name, family):
    if 'swamp' in name: return 'swamp'
    if 'river' in name: return 'alpine' if 'frozen' in name else 'river'
    if 'deep' in name and 'ocean' in name: return 'deep'
    if 'warm_ocean' in name or family == 'tropical': return 'tropical'
    if family == 'alpine': return 'alpine'
    if 'ocean' in name: return 'ocean'
    return 'clear'

def main():
    PACK.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    write(PACK/'manifest.json',{
        'format_version':2,
        'header':{'name':'SATURN X | AURORA','description':'Golden light, cinematic skies and clear water. Requires Vibrant Visuals. v1.0.0',
                  'uuid':'2f21dc79-bfee-4cb3-aec4-a35ce5820cf2','version':[1,0,0],'min_engine_version':[1,21,120]},
        'modules':[{'type':'resources','uuid':'adc92f7a-81ef-49f8-a960-19b71943d1d8','version':[1,0,0]}],
        'capabilities':['pbr'],
        'subpacks':[{'folder_name':'calm','name':'CALM | Same lighting, wave effect off','memory_tier':0},
                    {'folder_name':'cinematic','name':'CINEMATIC | Full water waves','memory_tier':0}],
        'metadata':{'authors':['BM / SATURN X'],'url':'https://github.com/jrjhdjio/SATURN-X/tree/main/minecraft/aurora'}
    })
    families = {
        'temperate':(1,.90,.028,1.06,6500), 'tropical':(.97,.95,.028,1.075,6500),
        'arid':(1.05,.90,.026,1.035,6700), 'alpine':(.94,.98,.03,1.035,6200),
        'cherry':(.98,.95,.03,1.05,6600), 'mystic':(.85,.84,.027,1.025,6350),
    }
    for fam,(power,sky,ambient,saturation,temp) in families.items():
        write(PACK/f'lighting/{fam}.json',make_lighting(f'light_{fam}',power,sky,ambient))
        write(PACK/f'atmospherics/{fam}.json',make_atmos(f'atmos_{fam}',fam))
        write(PACK/f'color_grading/{fam}.json',make_grade(f'grade_{fam}',saturation,temp))
    # Global fallbacks use distinct identifiers, so no duplicate definitions.
    write(PACK/'lighting/global.json',make_lighting('light_fallback'))
    write(PACK/'atmospherics/atmospherics.json',make_atmos('atmos_fallback','temperate'))
    write(PACK/'color_grading/color_grading.json',make_grade('grade_fallback'))
    for fam in ['cave','nether','end']:
        write(PACK/f'color_grading/{fam}.json',make_grade(f'grade_{fam}',1.035,6500,1.025))
    for name,vals in WATER.items():
        filename = 'water.json' if name=='clear' else f'{name}.json'
        water=make_water(name,vals)
        write(PACK/f'water/{filename}',water)
        write(PACK/f'subpacks/cinematic/water/{filename}',water)
        write(PACK/f'subpacks/calm/water/{filename}',make_water(name,vals,calm=True))
    write(PACK/'shadows/global.json',{'format_version':'1.21.80','minecraft:shadow_settings':{'shadow_style':'soft_shadows','texel_size':16}})
    # Point lights already supported by vanilla; no behavior/light-level changes.
    colors={'torch':'#FFD296','lantern':'#FFBC78','soul_torch':'#75DCFF',
            'soul_lantern':'#75DCFF','end_rod':'#DFD3FF','redstone_torch':'#FF503E',
            'candle':'#FFD296','sea_pickle':'#BCEDC3'}
    write(PACK/'local_lighting/local_lighting.json',{'format_version':'1.21.120',
          'minecraft:local_light_settings':{f'minecraft:{k}':{'light_color':v,'light_type':'point_light'} for k,v in colors.items()}})
    biomes=sorted((REF/'resource_pack/biomes').glob('*.client_biome.json'))
    if len(biomes)<80: raise RuntimeError('Official biome download incomplete')
    assignments=[]
    for src in biomes:
        data=json.loads(src.read_text())
        # The two newer 26.x biomes retain their native settings on those games.
        if tuple(map(int,data['format_version'].split('.'))) > (1,21,120): continue
        b=data['minecraft:client_biome']; name=b['description']['identifier'].split(':')[-1]
        family=group(name); comp=b['components']
        # Preserve fog, precipitation, native cave/dimension atmosphere, sounds,
        # music, foliage and all other vanilla client behavior byte-equivalently.
        comp['minecraft:color_grading_identifier']={'color_grading_identifier':f'{NS}:grade_{family}'}
        if family not in {'nether','end','cave'}:
            comp['minecraft:lighting_identifier']={'lighting_identifier':f'{NS}:light_{family}'}
            comp['minecraft:atmosphere_identifier']={'atmosphere_identifier':f'{NS}:atmos_{family}'}
        wg=water_group(name,family)
        if family not in {'nether','end'}:
            comp['minecraft:water_identifier']={'water_identifier':f'{NS}:water_{wg}'}
        write(PACK/'biomes'/src.name,data)
        assignments.append({'biome':name,'look':family,'water':wg if family not in {'nether','end'} else 'vanilla'})
    write(ROOT/'biome_assignments.json',assignments)
    shutil.copyfile(REF/'LICENSE.md',PACK/'MOJANG-LICENSE.md')
    shutil.copyfile(ROOT/'README.md',PACK/'README.md')
    shutil.copyfile(ROOT/'THIRD_PARTY_NOTICES.md',PACK/'THIRD_PARTY_NOTICES.md')
    if (REF/'UPSTREAM.json').exists(): shutil.copyfile(REF/'UPSTREAM.json',ROOT/'UPSTREAM.json')
    # Reproducible archive; manifest is at the ZIP root, never a wrapper folder.
    dest=OUT/'SATURN_X_AURORA_1.0.0.mcpack'
    with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(PACK.rglob('*')):
            if p.is_file():
                info=zipfile.ZipInfo(p.relative_to(PACK).as_posix(),(2026,10,22,0,0,0))
                info.compress_type=zipfile.ZIP_DEFLATED
                z.writestr(info,p.read_bytes())
    print(json.dumps({'mcpack':str(dest),'bytes':dest.stat().st_size,'biomes':len(assignments)}))

if __name__=='__main__': main()
