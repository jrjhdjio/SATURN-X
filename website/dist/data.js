export const REPO = 'https://github.com/jrjhdjio/SATURN-X';
export const RAW = 'https://raw.githubusercontent.com/jrjhdjio/SATURN-X/main/';
export const categories = [
  ['all','ทั้งหมด'], ['utility','เครื่องมือ'], ['avatar','แต่งตัว'], ['horror','สยองขวัญ'],
  ['adventure','ผจญภัย'], ['action','แอ็กชัน'], ['social','บันเทิง'], ['personal','ของฉัน']
];
const olderNote = 'ไฟล์ต้นฉบับอยู่บน GitHub การทำงานขึ้นอยู่กับเกมและสภาพแวดล้อมที่ใช้';
export const scripts = [
  {id:'mini',title:'SATURN X MINI',game:'UNIVERSAL TOOLS',category:'utility',file:'SATURN_X_MINI.lua',art:'mini',tone:'#1e2a3c',badge:'ESSENTIAL',description:'บิน ปรับความเร็ว และบันทึกพิกัด เครื่องมือทั่วไปในเมนูขนาดเดิม',tags:['บิน / Fly','ปรับความเร็ว','บันทึกพิกัด'],details:'รวมการบิน ปรับความเร็วเดินและกระโดด กระโดดกลางอากาศ เดินทะลุ ปรับความสว่างและ FOV พร้อมบันทึกพิกัดได้ 8 จุดในครั้งที่ใช้\nMINI คือรุ่นเครื่องมือทั่วไป โดยยังใช้ขนาดเมนูเดิม พร้อมเสียงและภาษาไทย / English / 中文',note:'ผ่านการตรวจด้วยแบบจำลอง ยังไม่ได้ทดสอบใน Roblox / Delta จริง',docs:'MINI.md'},
  {id:'avatar',title:'SATURN X AVATAR',game:'AVATAR STUDIO',category:'avatar',file:'SATURN_X_AVATAR.lua',art:'avatar',tone:'#282337',badge:'NEW',description:'ใส่ Username แล้วลองชุดจากโปรไฟล์ พร้อมตัวอย่างตัวละคร 3 มิติ',tags:['Username','ตัวอย่าง 3 มิติ','Local only'],details:'กรอก Username จริง เพื่อโหลดชุดจากโปรไฟล์ Roblox หมุนตัวอย่าง 3 มิติ ลองชุด และคืนชุดเดิมได้ พร้อมจำรายชื่อล่าสุด 8 ชื่อในครั้งที่ใช้',note:'เห็นชุดที่ลองเฉพาะเครื่องเรา ผู้เล่นอื่นยังเห็นชุดเดิม ไม่เปลี่ยนชุดบนบัญชี รุ่นทดลอง ยังไม่ได้ทดสอบใน Roblox / Delta จริง',docs:'AVATAR.md'},
  {id:'cat',title:'7 Days Cat-Sitting',game:'SATURN X · CAT SITTING',category:'horror',file:'SATURN_X_CAT_SITTING.lua',art:'cat',tone:'#293026',badge:'NEW',description:'ค้นหาแมวและจุดกดที่โหลดอยู่ แสดงระยะ และเดินไปยังจุดที่เลือก',tags:['ค้นหาจุดกด','ป้ายระยะ','เดินตามเส้นทาง'],details:'ค้นหาชื่อเกี่ยวกับแมว รวมถึง ProximityPrompt และ ClickDetector ที่โหลดอยู่ กรองชื่อ เลือกเป้าหมาย และเดินตามเส้นทางได้\nใช้กับ Place ID 116802325837172 พร้อมเครื่องมือเคลื่อนที่และภาพจาก MINI',note:'ค้นหาจากชื่อและจุดกดที่โหลดอยู่ อาจคลาดเคลื่อน ไม่ใช่ Auto Play หรือรับประกันผ่าน 7 วัน ยังไม่ได้ทดสอบในเกมจริง',docs:'CAT_SITTING.md'},
  {id:'doors',title:'DOORS',game:'SATURN X · DOORS',category:'horror',file:'SATURN_X_DOORS.lua',art:'doors',tone:'#332b25',badge:'GAME',description:'สคริปต์ SATURN X สำหรับ DOORS พร้อมเมนู เสียง และตัวเลือกภาษา',tags:['DOORS','3 ภาษา','เมนู SATURN X'],details:'สคริปต์เฉพาะเกม DOORS ในคอลเลกชัน SATURN X เปิดดูซอร์สโค้ดบน GitHub เพื่อดูรายละเอียดของรุ่นปัจจุบัน',note:olderNote},
  {id:'rails',title:'Dead Rails',game:'SATURN X · DEAD RAILS',category:'adventure',file:'SATURN_X_DEAD_RAILS.lua',art:'rails',tone:'#322b27',badge:'GAME',description:'เก็บสคริปต์ Dead Rails ไว้ใกล้มือ เปิดไฟล์ต้นฉบับหรือคัดลอกได้ทันที',tags:['Dead Rails','3 ภาษา','เมนู SATURN X'],details:'สคริปต์เฉพาะเกม Dead Rails ในคอลเลกชัน SATURN X พร้อมระบบสื่อร่วมและเมนู 3 ภาษา',note:olderNote},
  {id:'fisch',title:'Fisch',game:'SATURN X · FISCH',category:'adventure',file:'SATURN_X_FISCH.lua',art:'fisch',tone:'#173332',badge:'GAME',description:'สคริปต์สำหรับ Fisch รวมไว้ในคลังเดียวกับเครื่องมือ SATURN X ตัวอื่น',tags:['Fisch','3 ภาษา','เมนู SATURN X'],details:'สคริปต์เฉพาะเกม Fisch ในคอลเลกชัน SATURN X เปิดดูซอร์สโค้ดเพื่ออ่านฟังก์ชันของรุ่นปัจจุบัน',note:olderNote},
  {id:'sea',title:'100 Days At Sea',game:'SATURN X · ORIGINAL',category:'adventure',file:'SATURN_X.lua',art:'sea',tone:'#1b2f3d',badge:'ORIGINAL',description:'SATURN X รุ่นหลักสำหรับ 100 Days At Sea พร้อมธีมและระบบเสียง',tags:['At Sea','รุ่นหลัก','3 ภาษา'],details:'SATURN X รุ่นหลักสำหรับ 100 Days At Sea ใช้ไฟล์ SATURN_X.lua จากคลังต้นฉบับ',note:olderNote},
  {id:'mm2',title:'Murder Mystery 2',game:'SATURN X · MM2',category:'action',file:'SATURN_X_MM2.lua',art:'mm2',tone:'#352228',badge:'GAME',description:'สคริปต์ SATURN X สำหรับ MM2 พร้อมลิงก์ต้นฉบับและโค้ดพร้อมคัดลอก',tags:['MM2','3 ภาษา','เมนู SATURN X'],details:'สคริปต์เฉพาะเกม Murder Mystery 2 ในคอลเลกชัน SATURN X พร้อมระบบเสียงและภาษาไทย / English / 中文',note:olderNote},
  {id:'hypershot',title:'Hypershot',game:'SATURN X · HYPERSHOT',category:'action',file:'SATURN_X_HYPERSHOT.lua',art:'hypershot',tone:'#202939',badge:'GAME',description:'เปิดสคริปต์ Hypershot จากคอลเลกชันของคุณ ด้วยปุ่มคัดลอกเพียงครั้งเดียว',tags:['Hypershot','3 ภาษา','เมนู SATURN X'],details:'สคริปต์เฉพาะเกม Hypershot ในคอลเลกชัน SATURN X เปิดดูซอร์สโค้ดเพื่ออ่านรายละเอียดของรุ่นปัจจุบัน',note:olderNote},
  {id:'dance',title:'SATURN X DANCE',game:'DANCE COLLECTION',category:'social',file:'SATURN_X_DANCE.lua',art:'dance',tone:'#32263c',badge:'SOCIAL',description:'เก็บรุ่น DANCE ไว้ในหมวดบันเทิง พร้อมเมนูและระบบสื่อของ SATURN X',tags:['Dance','3 ภาษา','เมนู SATURN X'],details:'SATURN X รุ่น DANCE พร้อมระบบสื่อร่วม โลโก้ เสียงเปิด–ปิด และตัวเลือกภาษา',note:olderNote}
];
export function codeFor(script) { return script.custom ? script.code : `loadstring(game:HttpGet("${RAW}${script.file}"))()`; }
export function filteredScripts(items, {query='',category='all',view='all',sort='default'}, favorites) {
  const q=query.trim().toLocaleLowerCase();
  const result=items.filter(s=>(view!=='favorites'||favorites.includes(s.id))&&(category==='all'||(category==='personal'?s.custom:s.category===category))&&(!q||[s.title,s.game,s.description,...(s.tags||[])].join(' ').toLocaleLowerCase().includes(q)));
  if(sort==='name')result.sort((a,b)=>a.title.localeCompare(b.title,'th'));
  if(sort==='custom')result.sort((a,b)=>Number(!!b.custom)-Number(!!a.custom));
  return result;
}
export function validateCustom(s) {
  if(!s||typeof s!=='object'||typeof s.title!=='string'||!s.title.trim()||s.title.length>80||typeof s.code!=='string'||!s.code.trim()||s.code.length>50000)throw new Error('ชื่อหรือโค้ดสคริปต์ไม่ถูกต้อง');
  if(s.description!=null&&(typeof s.description!=='string'||s.description.length>300))throw new Error('คำอธิบายยาวเกิน 300 ตัวอักษร');
  if(s.game!=null&&(typeof s.game!=='string'||s.game.length>60))throw new Error('ชื่อเกมยาวเกิน 60 ตัวอักษร');
  const category=categories.some(c=>c[0]===s.category&&!['all','personal'].includes(c[0]))?s.category:'utility';
  const id=typeof s.id==='string'&&/^custom-[a-zA-Z0-9-]{1,80}$/.test(s.id)?s.id:`custom-${crypto.randomUUID()}`;
  return {id,title:s.title.trim(),code:s.code,description:(s.description||'').trim(),game:(s.game||'MY COLLECTION').trim(),category,custom:true,art:'custom',tone:'#243039',badge:'MY SCRIPT',tags:['ของฉัน',categories.find(c=>c[0]===category)[1]]};
}
export function validateBackup(data) {
  if(!data||data.format!=='saturn-x-vault'||data.version!==1||!Array.isArray(data.scripts)||data.scripts.length>100||!Array.isArray(data.favorites)||data.favorites.length>110)throw new Error('ไฟล์นี้ไม่ใช่ไฟล์สำรอง SATURN X ที่รองรับ');
  if(!data.favorites.every(s=>typeof s==='string'&&s.length<100))throw new Error('รายการโปรดในไฟล์ไม่ถูกต้อง');
  const clean=data.scripts.map(validateCustom);
  if(new Set(clean.map(s=>s.id)).size!==clean.length)throw new Error('พบรหัสสคริปต์ซ้ำในไฟล์');
  return {scripts:clean,favorites:[...new Set(data.favorites)]};
}
export function mergedBackup(current,incoming) {
  const result=[...current.scripts];
  const remap=new Map();
  for(const entry of incoming.scripts){
    const duplicate=result.find(s=>s.title===entry.title&&s.code===entry.code);
    if(duplicate){remap.set(entry.id,duplicate.id);continue;}
    const id=result.some(s=>s.id===entry.id)?`custom-${crypto.randomUUID()}`:entry.id;
    remap.set(entry.id,id);
    result.push({...entry,id});
  }
  if(result.length>100)throw new Error('เก็บได้สูงสุด 100 สคริปต์ส่วนตัว กรุณาส่งออกและลบบางรายการก่อน');
  const known=new Set([...scripts,...result].map(s=>s.id));
  return {scripts:result,favorites:[...new Set([...current.favorites,...incoming.favorites.map(id=>remap.get(id)||id)])].filter(id=>known.has(id))};
}
