import {scripts,categories,REPO,RAW,codeFor,filteredScripts,validateCustom,validateBackup,mergedBackup} from './data.js';
import {artwork} from './art.js';

const $=s=>document.querySelector(s);
const $$=s=>[...document.querySelectorAll(s)];
const esc=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const KEY='saturn-x-vault-v1';
const copyIcon='<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V4a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v11a1 1 0 0 0 1 1h4"/></svg>';
const starIcon='<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m12 3 2.8 5.7 6.3.9-4.6 4.4 1.1 6.3-5.6-3-5.6 3 1.1-6.3-4.6-4.4 6.3-.9z"/></svg>';
let personal={scripts:[],favorites:[]};
let storageIssue='';
try{
 const raw=localStorage.getItem(KEY);
 if(raw)personal=validateBackup(JSON.parse(raw));
}catch{storageIssue='อ่านคลังที่บันทึกไว้ไม่ได้ ข้อมูลเดิมยังไม่ถูกแก้ไข';}
const view={query:'',category:'all',view:'all',sort:'default',layout:'grid'};
let toastTimer,deleteId=null,detailId=null;
const allScripts=()=>[...scripts,...personal.scripts];
const findScript=id=>allScripts().find(s=>s.id===id);
function toast(message){$('#toast').textContent=message;$('#toast').classList.add('visible');clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('#toast').classList.remove('visible'),3600);}
function persist(next){
 try{localStorage.setItem(KEY,JSON.stringify({format:'saturn-x-vault',version:1,...next}));personal=next;storageIssue='';return true;}
 catch{toast('บันทึกไม่ได้ พื้นที่เบราว์เซอร์อาจเต็มหรือถูกปิดกั้น กรุณาส่งออกไฟล์สำรอง');return false;}
}
function openDialog(selector){const el=$(selector);$$('dialog[open]').forEach(d=>d.close());el.showModal();document.body.style.overflow='hidden';}
$$('dialog').forEach(d=>{
 d.addEventListener('close',()=>{if(!document.querySelector('dialog[open]'))document.body.style.overflow='';});
 d.addEventListener('click',e=>{if(e.target===d){const r=d.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)d.close();}});
});
$('#categories').innerHTML=categories.map(([id,label])=>`<button class="category-button ${id==='all'?'active':''}" data-category="${id}" aria-pressed="${id==='all'}">${label}</button>`).join('');
$('#form-category').innerHTML=categories.filter(c=>!['all','personal'].includes(c[0])).map(([id,label])=>`<option value="${id}">${label}</option>`).join('');

function render(){
 const items=allScripts();
 const known=new Set(items.map(s=>s.id));
 const matches=filteredScripts(items,view,personal.favorites);
 $('#total-count').textContent=view.view==='favorites'?personal.favorites.filter(id=>known.has(id)).length:items.length;
 $('#favorite-count').textContent=personal.favorites.filter(id=>known.has(id)).length;
 $('#library-title').firstChild.textContent=view.view==='favorites'?'รายการโปรด ':'คลังสคริปต์ ';
 $('#result-count').textContent=`แสดง ${matches.length} สคริปต์${view.query?' จากการค้นหา':''}`;
 $('#view-note').textContent=view.view==='favorites'?'วงโคจรส่วนตัวของคุณ':'เลือกสิ่งที่ใช่ แล้วเก็บไว้ในวงโคจรของคุณ';
 const grid=$('#script-grid');
 grid.classList.toggle('list-mode',view.layout==='list');
 grid.innerHTML=matches.map((s,index)=>{
  const saved=personal.favorites.includes(s.id);
  return `<article class="script-card" data-script="${esc(s.id)}"><div class="card-art" style="--art-bg:${s.tone}">${artwork(s.art,s.id)}<span class="art-index">SX / ${String(items.indexOf(s)+1).padStart(2,'0')}</span><span class="art-label">${s.custom?'PERSONAL COLLECTION':'SATURN X COLLECTION'}</span><button class="icon-button favorite-button ${saved?'saved':''}" data-favorite="${esc(s.id)}" aria-pressed="${saved}" aria-label="${saved?'นำออกจาก':'เพิ่มใน'}รายการโปรด: ${esc(s.title)}" title="${saved?'นำออกจาก':'เพิ่มใน'}รายการโปรด">${starIcon}</button></div><div class="card-body"><div class="card-heading"><h3><button class="card-title-button" data-detail="${esc(s.id)}">${esc(s.title)}</button></h3><span class="card-badge ${s.badge==='NEW'?'fresh':''}">${s.badge}</span></div><p class="card-game">${esc(s.game)}</p><p class="card-description">${esc(s.description||'สคริปต์ในคอลเลกชันส่วนตัวของคุณ')}</p><div class="card-tags">${s.tags.map(t=>`<span class="tag">${esc(t)}</span>`).join('')}</div><div class="card-actions"><button class="button copy-button" data-copy="${esc(s.id)}">${copyIcon}<span>คัดลอกสคริปต์</span></button><button class="icon-button details-button" data-detail="${esc(s.id)}" aria-label="รายละเอียด ${esc(s.title)}" title="รายละเอียด">↗</button></div></div></article>`;
 }).join('');
 $('#empty-state').hidden=matches.length>0;
 $('#empty-title').textContent=view.view==='favorites'&&!personal.favorites.length?'วงโคจรนี้ยังว่างอยู่':'ยังไม่พบสคริปต์';
 $('#empty-description').textContent=view.view==='favorites'&&!personal.favorites.length?'กดดาวบนการ์ด เพื่อเก็บสคริปต์ที่ใช้บ่อยไว้ที่นี่':'ลองค้นหาด้วยคำอื่น หรือเลือกหมวดทั้งหมด';
 $$('[data-category]').forEach(b=>{const active=b.dataset.category===view.category;b.classList.toggle('active',active);b.setAttribute('aria-pressed',String(active));});
 $$('[data-view]').forEach(b=>{const active=b.dataset.view===view.view;b.classList.toggle('active',active);if(active)b.setAttribute('aria-current','page');else b.removeAttribute('aria-current');});
}
function setView(next){view.view=next;render();$('#library').scrollIntoView({behavior:'smooth'});}
function resetFilters(){Object.assign(view,{query:'',category:'all',view:'all',sort:'default'});$('#search').value='';$('#sort').value='default';render();}
function showDetail(id){
 const s=findScript(id);if(!s)return;
 detailId=id;
 $('#detail-content').innerHTML=`<div class="detail-art" style="--art-bg:${s.tone}">${artwork(s.art,'detail')}</div><div class="detail-inner"><div class="detail-meta"><span>${esc(s.game)}</span><span>·</span><span>${categories.find(c=>c[0]===s.category)?.[1]||'ของฉัน'}</span></div><h2 id="detail-title">${esc(s.title)}</h2><div class="card-tags">${s.tags.map(t=>`<span class="tag">${esc(t)}</span>`).join('')}</div><p class="detail-description">${esc(s.details||s.description||'สคริปต์ในคอลเลกชันส่วนตัวของคุณ')}</p>${s.note?`<p class="detail-notice">${esc(s.note)}</p>`:''}<div class="code-box"><div class="code-header"><span>${s.custom?'LUA SCRIPT':'LOADER · LUA'}</span><button class="button outline" data-copy="${esc(id)}">${copyIcon}<span>คัดลอก</span></button></div><pre tabindex="0"><code>${esc(codeFor(s))}</code></pre></div><div class="detail-links">${s.custom?`<button class="button outline" data-edit="${esc(id)}">แก้ไขสคริปต์</button><button class="button text-button danger-text" data-delete="${esc(id)}">ลบสคริปต์</button>`:`<a class="button outline" href="${REPO}/blob/main/${s.file}" target="_blank" rel="noopener noreferrer">ดูบน GitHub ↗</a><a class="button text-button" href="${RAW}${s.file}" target="_blank" rel="noopener noreferrer">ไฟล์ Raw ↗</a>${s.docs?`<a class="button text-button" href="${REPO}/blob/main/${s.docs}" target="_blank" rel="noopener noreferrer">คู่มือ ↗</a>`:''}`}</div></div>`;
 openDialog('#detail-dialog');
}
async function copyScript(id,button){
 const s=findScript(id);if(!s)return;
 const code=codeFor(s);let copied=false;
 try{if(navigator.clipboard?.writeText){await navigator.clipboard.writeText(code);copied=true;}}catch{}
 if(!copied){
  const area=document.createElement('textarea');area.value=code;area.setAttribute('readonly','');area.style.cssText='position:fixed;top:0;left:0;width:1px;height:1px;opacity:0';
  (document.querySelector('dialog[open]')||document.body).append(area);area.focus();area.select();area.setSelectionRange(0,code.length);
  try{copied=document.execCommand('copy');}catch{}area.remove();button?.focus({preventScroll:true});
 }
 if(copied){toast(`คัดลอก ${s.title} แล้ว`);if(button?.isConnected){const label=button.querySelector('span');if(label){const before=label.textContent;label.textContent='คัดลอกแล้ว ✓';setTimeout(()=>{if(label.isConnected)label.textContent=before;},1800);}}}
 else{showDetail(id);toast('เบราว์เซอร์ไม่อนุญาตให้คัดลอก กรุณาเลือกโค้ดในช่องแล้วคัดลอกเอง');const range=document.createRange();range.selectNodeContents($('#detail-content code'));const selection=window.getSelection();selection.removeAllRanges();selection.addRange(range);}
}
function openForm(id){
 $('#script-form').reset();$('#form-error').textContent='';
 const form=$('#script-form'),s=id?findScript(id):null;
 form.elements.id.value=s?.custom?s.id:'';
 $('#add-title').textContent=s?.custom?'แก้ไขสคริปต์':'เพิ่มสคริปต์ของฉัน';
 if(s?.custom){for(const k of ['title','game','description','category','code'])form.elements[k].value=s[k]||'';}
 openDialog('#add-dialog');
 form.elements.title.focus();
}
document.addEventListener('click',e=>{
 const b=e.target.closest('button');if(!b)return;
 if(b.hasAttribute('data-close')){b.closest('dialog')?.close();return;}
 if(b.dataset.action==='add'){openForm();return;}
 if(b.dataset.detail){showDetail(b.dataset.detail);return;}
 if(b.dataset.copy){copyScript(b.dataset.copy,b);return;}
 if(b.dataset.edit){openForm(b.dataset.edit);return;}
 if(b.dataset.delete){const s=findScript(b.dataset.delete);if(!s?.custom)return;deleteId=s.id;$('#delete-description').textContent=`“${s.title}” จะถูกนำออกจากคลังในเบราว์เซอร์นี้`;openDialog('#delete-dialog');return;}
 if(b.dataset.favorite){const id=b.dataset.favorite;if(!findScript(id))return;const saved=personal.favorites.includes(id);if(persist({...personal,favorites:saved?personal.favorites.filter(f=>f!==id):[...personal.favorites,id]})){render();document.querySelector(`[data-favorite="${id}"]`)?.focus({preventScroll:true});toast(saved?'นำออกจากรายการโปรดแล้ว':'เพิ่มในรายการโปรดแล้ว');}return;}
 if(b.dataset.category){view.category=b.dataset.category;render();document.querySelector(`[data-category="${view.category}"]`)?.focus({preventScroll:true});return;}
 if(b.dataset.view){setView(b.dataset.view);return;}
 if(b.dataset.layout){view.layout=b.dataset.layout;$$('[data-layout]').forEach(x=>{x.classList.toggle('active',x===b);x.setAttribute('aria-pressed',String(x===b));});render();}
});
$('#script-form').addEventListener('submit',e=>{
 e.preventDefault();$('#form-error').textContent='';const form=e.currentTarget;
 try{
  const data=Object.fromEntries(new FormData(form));
  if(!data.id&&personal.scripts.length>=100)throw new Error('เก็บได้สูงสุด 100 สคริปต์ส่วนตัว');
  const entry=validateCustom(data);
  const editing=personal.scripts.some(s=>s.id===entry.id);
  const next=editing?personal.scripts.map(s=>s.id===entry.id?entry:s):[entry,...personal.scripts];
  if(!persist({...personal,scripts:next}))return;
  $('#add-dialog').close();resetFilters();view.category='personal';render();$('#library').scrollIntoView({behavior:'smooth'});toast(editing?'บันทึกการแก้ไขแล้ว':'เพิ่มสคริปต์ในคลังแล้ว');
 }catch(err){$('#form-error').textContent=err.message;}
});
$('#confirm-delete').addEventListener('click',()=>{
 if(!personal.scripts.some(s=>s.id===deleteId))return;
 if(persist({scripts:personal.scripts.filter(s=>s.id!==deleteId),favorites:personal.favorites.filter(s=>s!==deleteId)})){$('#delete-dialog').close();deleteId=null;render();toast('ลบสคริปต์แล้ว');}
});
$('#search').addEventListener('input',e=>{view.query=e.target.value;render();});
$('#sort').addEventListener('change',e=>{view.sort=e.target.value;render();});
$('#clear-filters').addEventListener('click',resetFilters);
$('#guide-button').addEventListener('click',()=>openDialog('#guide-dialog'));
$('#backup-button').addEventListener('click',()=>{$('#backup-message').textContent='';openDialog('#backup-dialog');});
$('#export-button').addEventListener('click',()=>{
 const data={format:'saturn-x-vault',version:1,exportedAt:new Date().toISOString(),...personal};
 const url=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=`saturn-x-vault-${new Date().toISOString().slice(0,10)}.json`;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);$('#backup-message').textContent=`ส่งออก ${personal.scripts.length} สคริปต์ส่วนตัว และ ${personal.favorites.length} รายการโปรดแล้ว`;
});
$('#import-button').addEventListener('click',()=>$('#import-file').click());
$('#import-file').addEventListener('change',async e=>{
 const file=e.target.files[0];if(!file)return;$('#backup-message').textContent='กำลังตรวจไฟล์…';
 try{if(file.size>6000000)throw new Error('ไฟล์ใหญ่เกิน 6 MB');const parsed=validateBackup(JSON.parse(await file.text()));const merged=mergedBackup(personal,parsed);const added=merged.scripts.length-personal.scripts.length;if(persist(merged)){render();$('#backup-message').textContent=`นำเข้าสำเร็จ เพิ่ม ${added} สคริปต์ และรวมรายการโปรดแล้ว`;}else $('#backup-message').textContent='บันทึกไม่สำเร็จ คลังเดิมยังอยู่';}
 catch(err){$('#backup-message').textContent=`นำเข้าไม่ได้: ${err instanceof SyntaxError?'รูปแบบ JSON ไม่ถูกต้อง':err.message}`;}
 e.target.value='';
});
document.addEventListener('keydown',e=>{
 if(e.key==='/'&&!e.ctrlKey&&!e.metaKey&&!document.querySelector('dialog[open]')&&!['INPUT','TEXTAREA','SELECT'].includes(document.activeElement?.tagName)){e.preventDefault();$('#search').focus();$('#library').scrollIntoView({behavior:'smooth'});}
});
window.addEventListener('storage',e=>{if(e.key!==KEY)return;try{personal=e.newValue?validateBackup(JSON.parse(e.newValue)):{scripts:[],favorites:[]};render();if($('#detail-dialog').open&&detailId&&!findScript(detailId))$('#detail-dialog').close();}catch{toast('มีข้อมูลจากแท็บอื่นที่อ่านไม่ได้ คลังในหน้านี้ยังอยู่');}});
render();
if(storageIssue)setTimeout(()=>toast(storageIssue),800);
