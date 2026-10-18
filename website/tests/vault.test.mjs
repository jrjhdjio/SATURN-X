import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
import {scripts,codeFor,filteredScripts,validateCustom,validateBackup,mergedBackup} from '../dist/data.js';
import {artwork} from '../dist/art.js';
const valid=(id='custom-test',title='My script',code='print("hello")')=>validateCustom({id,title,code,category:'utility'});
const backup=entries=>({format:'saturn-x-vault',version:1,scripts:entries,favorites:[]});
test('all ten catalog loaders match verified GitHub filenames',()=>{
 const expected=['SATURN_X.lua','SATURN_X_AVATAR.lua','SATURN_X_CAT_SITTING.lua','SATURN_X_DANCE.lua','SATURN_X_DEAD_RAILS.lua','SATURN_X_DOORS.lua','SATURN_X_FISCH.lua','SATURN_X_HYPERSHOT.lua','SATURN_X_MINI.lua','SATURN_X_MM2.lua'];
 assert.deepEqual(scripts.map(s=>s.file).sort(),expected);
 assert.equal(new Set(scripts.map(s=>s.id)).size,10);
 for(const s of scripts)assert.equal(codeFor(s),`loadstring(game:HttpGet("https://raw.githubusercontent.com/jrjhdjio/SATURN-X/main/${s.file}"))()`);
});
test('search, categories, favorites and sort combine correctly',()=>{
 assert.deepEqual(filteredScripts(scripts,{query:'  USERNAME  '},[]).map(s=>s.id),['avatar']);
 assert.equal(filteredScripts(scripts,{query:'บิน'},[])[0].id,'mini');
 assert.deepEqual(filteredScripts(scripts,{category:'horror',view:'favorites'},['doors','mini']).map(s=>s.id),['doors']);
 assert.equal(filteredScripts(scripts,{query:'zzzz-no-match'},[]).length,0);
 assert.equal(filteredScripts([...scripts,valid()],{category:'personal'},[]).length,1);
 assert.equal(filteredScripts([...scripts,valid()],{sort:'custom'},[])[0].custom,true);
});
test('custom code round-trips literally without interpreting markup',()=>{
 const code='<script>alert(1)</script>\nprint("<&>")';
 const s=valid('custom-markup','<img onerror=alert(1)>',code);
 assert.equal(codeFor(s),code);
 const restored=validateBackup(JSON.parse(JSON.stringify(backup([s]))));
 assert.equal(restored.scripts[0].code,code);
 assert.equal(restored.scripts[0].title,s.title);
});
test('imports cannot override catalog IDs or inject arbitrary presentation properties',()=>{
 const s=validateCustom({id:'mini',title:'Custom',code:'print(1)',category:'<script>',tone:'url(evil)',custom:false,file:'other.lua'});
 assert.match(s.id,/^custom-/);assert.equal(s.category,'utility');assert.equal(s.custom,true);assert.equal(s.tone,'#243039');assert.equal(s.file,undefined);
});
test('malformed and over-limit backups are rejected before changing data',()=>{
 for(const d of [null,{}, {...backup([]),version:2},{...backup([]),favorites:[{}]},backup([{title:'x',code:''}]),backup([valid(),valid()]),backup(Array.from({length:101},(_,i)=>valid('custom-'+i)))])assert.throws(()=>validateBackup(d));
 for(const s of [{title:' ',code:'a'},{title:'x'.repeat(81),code:'a'},{title:'x',code:'a'.repeat(50001)},{title:'x',code:'a',game:{}},{title:'x',code:'a',description:'a'.repeat(301)}])assert.throws(()=>validateCustom(s));
});
test('merging duplicates preserves originals and maps favorites',()=>{
 const old=valid('custom-old');const imported=valid('custom-new');
 const current={scripts:[old],favorites:['mini']};
 const result=mergedBackup(current,{scripts:[imported],favorites:['custom-new','missing']});
 assert.equal(result.scripts.length,1);assert.deepEqual(result.favorites,['mini','custom-old']);assert.deepEqual(current,{scripts:[old],favorites:['mini']});
});
test('ID collision keeps both different scripts and favorites the imported version',()=>{
 const old=valid();const next=valid('custom-test','Other','print("other")');
 const result=mergedBackup({scripts:[old],favorites:[]},{scripts:[next],favorites:['custom-test']});
 assert.equal(result.scripts.length,2);assert.notEqual(result.scripts[1].id,old.id);assert.deepEqual(result.favorites,[result.scripts[1].id]);
});
test('full backup round-trip keeps custom records and built-in favorites',()=>{
 const source={...backup([valid()]),favorites:['mini','custom-test']};
 const parsed=validateBackup(JSON.parse(JSON.stringify(source)));
 assert.deepEqual(mergedBackup({scripts:[],favorites:[]},parsed),{scripts:source.scripts,favorites:source.favorites});
});
test('over-capacity merge fails without mutating either input',()=>{
 const current={scripts:Array.from({length:100},(_,i)=>valid('custom-'+i,'name'+i)),favorites:[]};
 const incoming={scripts:[valid('custom-extra','extra')],favorites:[]};
 assert.throws(()=>mergedBackup(current,incoming));assert.equal(current.scripts.length,100);assert.equal(incoming.scripts.length,1);
});
test('each illustration has an isolated SVG gradient namespace',()=>{
 for(const s of scripts){const svg=artwork(s.art,s.id);assert.match(svg,/<svg /);assert.ok(!svg.includes('url(#metal)'));assert.ok(!svg.includes('url(#sphere)'));assert.ok(!svg.includes('undefined'));}
});
test('static entrypoint has assets, accessible dialog labels and no execution of stored code',()=>{
 const html=readFileSync(new URL('../dist/index.html',import.meta.url),'utf8');
 for(const file of ['styles.css','app.js','data.js','art.js','assets/mark.svg','assets/saturn.svg'])assert.ok(existsSync(new URL('../dist/'+file,import.meta.url)));
 assert.match(html,/<html lang="th">/);assert.match(html,/name="viewport"/);assert.equal((html.match(/<dialog /g)||[]).length,5);
 const app=readFileSync(new URL('../dist/app.js',import.meta.url),'utf8');
 assert.doesNotMatch(app,/\beval\s*\(|new Function\s*\(/);assert.ok(app.includes('esc(codeFor(s))'));
});
