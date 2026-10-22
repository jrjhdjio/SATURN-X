#!/usr/bin/env python3
"""Build SATURN X AURORA from official client biomes and authored VV settings.

Input: ../vanilla-reference, pinned in UPSTREAM.json. No runtime code or mods.
Rebuild with the Python standard library; pack_icon.png is a committed asset.
"""
import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REF = ROOT.parent / 'vanilla-reference'
PACK = ROOT / 'pack'
OUT = ROOT / 'dist'
NS = 'saturn_aurora'
VERSION = [2, 0, 0]
VERSION_TEXT = '.'.join(map(str, VERSION))

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def obj(kind, ident, version, **kw):
    return {'format_version': version, f'minecraft:{kind}_settings':
            {'description': {'identifier': f'{NS}:{ident}'}, **kw}}

def curve(*pairs):
    return {str(t): v for t, v in pairs}

def make_lighting(name, factor=1, sky=.95, ambient=.042):
    # Minecraft VV keys use noon=0; sunset=.25; midnight=.5; sunrise=.75.
    # Stay close to the shipped 26.50 sample's 100-lux noon calibration.
    lux = curve((0.0,104),(.17,65),(.23,26),(.25,17),(.282,1.0),(.292,0),
                (.5,0),(.709,0),(.719,1.0),(.75,19),(.82,60),(1.0,104))
    lux = {k:round(v * factor, 4) for k,v in lux.items()}
    color = curve((0.0,'#FFF1DC'),(.17,'#FFE1B5'),(.25,'#FFB16D'),(.30,'#EBA0B1'),
                  (.35,'#CDD9F9'),(.5,'#CDD9F9'),(.65,'#CDD9F9'),(.70,'#F2B9B0'),
                  (.75,'#FFC38B'),(.84,'#FFEAC5'),(1.0,'#FFF1DC'))
    return obj('lighting',name,'1.21.80',
        directional_lights={'orbital':{'sun':{'illuminance':lux,'color':color},
            'moon':{'illuminance':curve((0.0,0),(.20,0),(.23,.46),(.34,.56),(.5,.60),(.66,.56),(.735,.46),(.75,0),(1.0,0)),
                    'color':'#BED7FF'},'orbital_offset_degrees':0.0},
            'flash':{'illuminance':4.0,'color':'#CFB6FF'}},
        emissive={'desaturation':.12},ambient={'illuminance':ambient,'color':'#CCDCFA'},
        sky={'intensity':sky})

def make_atmos(name, family):
    day = {'temperate':'#286BA5','tropical':'#1E78AC','arid':'#487EA7',
           'alpine':'#3676A8','cherry':'#4C76AE','mystic':'#4D6388'}[family]
    horizon = {'temperate':'#8AB8D1','tropical':'#88C9CA','arid':'#C9BDA3',
               'alpine':'#A7CEDF','cherry':'#C7B4D1','mystic':'#92A6B8'}[family]
    return obj('atmosphere',name,'1.21.40',
        horizon_blend_stops={'min':0.0,'start':curve((0.0,.62),(.25,.38),(.35,.28),(.65,.28),(.75,.32),(1.0,.62)),
                             'mie_start':.55,'max':.25},
        rayleigh_strength=curve((0.0,6.8),(.20,5.8),(.25,4.6),(.34,4.7),
                                (.5,5.0),(.66,4.7),(.75,4.6),(.84,5.8),(1.0,6.8)),
        sun_mie_strength=curve((0.0,.015),(.18,.15),(.25,1.12),(.31,.25),
                               (.4,0),(.6,0),(.7,.25),(.75,.98),(.84,.15),(1.0,.015)),
        moon_mie_strength=curve((0.0,0),(.28,0),(.35,.035),(.5,.06),(.65,.035),(.72,0),(1.0,0)),
        sun_glare_shape=.06,
        sky_zenith_color=curve((0.0,day),(.18,day),(.25,'#684B8A'),(.33,'#323860'),
                               (.5,'#192A4C'),(.66,'#323860'),(.75,'#637AB0'),(.85,day),(1.0,day)),
        sky_horizon_color=curve((0.0,horizon),(.16,horizon),(.25,'#FFA473'),
                                (.30,'#CB7B9F'),(.36,'#6B6798'),(.5,'#526C9E'),
                                (.64,'#6B6798'),(.70,'#D68EA6'),(.75,'#FFC08C'),
                                (.86,horizon),(1.0,horizon)))

def make_grade(name, saturation=1.12, temperature=6500, contrast=1.11, outdoor=True):
    def band(gain, sat, con, gamma=2.2):
        return {'contrast':[con]*3,'gain':gain,'gamma':[gamma]*3,
                'offset':[0.0]*3,'saturation':[sat]*3}
    shadow=band([1.025,1.045,1.075],1.025,1.0,2.30) if outdoor else band([.99,1.0,1.025],1.0,1.015,2.23)
    if outdoor: shadow['offset']=[.002,.003,.005]
    shadow.update(enabled=True,shadowsMax=.70 if outdoor else .55)
    highlight=band([.970,.955,.935],1.035,1.015,2.18) if outdoor else band([1.015,1.0,.985],1.015,1.01)
    highlight.update(enabled=True,highlightsMin=1.8)
    return obj('color_grading',name,'1.21.90',
        color_grading={'midtones':band([1.0,1.0,1.0],saturation,contrast),
            'shadows':shadow,'highlights':highlight,
            'temperature':{'enabled':True,'temperature':temperature,'type':'color_temperature'}},
        tone_mapping={'operator':'aces'})

WATER = {
    # CDOM, chlorophyll, sediment, wave depth, frequency, speed
    'clear':(.04,.12,.06,.28,.32,.65),
    'ocean':(.025,.18,.08,.85,.24,.82),
    'tropical':(.015,.08,.035,.65,.29,.78),
    'deep':(.04,.35,.12,1.05,.20,.95),
    'river':(.30,.22,.35,.15,.48,.72),
    'alpine':(.02,.08,.035,.14,.38,.60),
    'swamp':(1.5,1.15,1.0,.08,.45,.45),
}

def make_water(name, values, preset='cinematic'):
    cdom, chl, sediment, depth, frequency, speed = values
    return obj('water',f'water_{name}','1.21.120',
        particle_concentrations={'cdom':cdom,'chlorophyll':chl,'suspended_sediment':sediment},
        # Broad swells: fewer high-frequency crests than v1, with more layers in
        # Ultra. These are image-based surface waves, not displaced geometry.
        waves={'enabled':preset!='calm','depth':depth if preset=='cinematic' else round(depth*.72,4),
               'direction_increment':80.0,'frequency':frequency,
               'frequency_scaling':1.17,'mix':.16,'octaves':16 if preset=='cinematic' else 8,
               'pull':.24,'shape':1.3,'speed':speed,'speed_scaling':1.015},
        caustics={'enabled':True,'frame_length':.065,'power':1,'scale':.45})

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
        'header':{'name':'SATURN X | AURORA 2 - ULTRA OCEAN','description':f'Rich cinematic color, golden sunsets, blue moonlight and rolling ocean waves. Requires Vibrant Visuals. v{VERSION_TEXT}',
                  'uuid':'2f21dc79-bfee-4cb3-aec4-a35ce5820cf2','version':VERSION,'min_engine_version':[1,21,120]},
        'modules':[{'type':'resources','uuid':'adc92f7a-81ef-49f8-a960-19b71943d1d8','version':VERSION}],
        'capabilities':['pbr'],
        'subpacks':[{'folder_name':'calm','name':'CALM | Same lighting, wave effect off','memory_tier':0},
                    {'folder_name':'balanced','name':'BALANCED | Cinematic color, lighter waves','memory_tier':0},
                    {'folder_name':'cinematic','name':'ULTRA OCEAN | Rich color and full ocean swells','memory_tier':0}],
        'metadata':{'authors':['BM / SATURN X'],'url':'https://github.com/jrjhdjio/SATURN-X/tree/main/minecraft/aurora'}
    })
    families = {
        'temperate':(1,.95,.042,1.12,6550), 'tropical':(.97,.98,.042,1.14,6500),
        'arid':(1.03,.94,.038,1.075,6750), 'alpine':(.94,1.0,.042,1.08,6250),
        'cherry':(.98,.98,.044,1.115,6600), 'mystic':(.85,.90,.039,1.07,6400),
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
        write(PACK/f'color_grading/{fam}.json',make_grade(f'grade_{fam}',1.035,6500,1.025,outdoor=False))
    for name,vals in WATER.items():
        filename = 'water.json' if name=='clear' else f'{name}.json'
        water=make_water(name,vals)
        write(PACK/f'water/{filename}',water)
        write(PACK/f'subpacks/cinematic/water/{filename}',water)
        write(PACK/f'subpacks/balanced/water/{filename}',make_water(name,vals,preset='balanced'))
        write(PACK/f'subpacks/calm/water/{filename}',make_water(name,vals,preset='calm'))
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
    dest=OUT/f'SATURN_X_AURORA_{VERSION_TEXT}_ULTRA_OCEAN.mcpack'
    with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(PACK.rglob('*')):
            if p.is_file():
                info=zipfile.ZipInfo(p.relative_to(PACK).as_posix(),(2026,10,22,0,0,0))
                info.compress_type=zipfile.ZIP_DEFLATED
                z.writestr(info,p.read_bytes())
    print(json.dumps({'mcpack':str(dest),'bytes':dest.stat().st_size,'biomes':len(assignments)}))

if __name__=='__main__': main()
