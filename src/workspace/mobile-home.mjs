const read=(k,f)=>{try{return JSON.parse(localStorage.getItem(k))??f}catch{return f}};
const save=(k,v)=>{try{localStorage.setItem(k,JSON.stringify(v))}catch{}};
const theme=read('hamriq-theme',matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light');
document.documentElement.dataset.theme=theme;
let dragging=null,timer=null,start=null;
function orderKey(){return 'hamriq-home-order:'+ (document.querySelector('.page-heading .eyebrow')?.textContent||'workspace')+':'+location.host}
function persist(){save(orderKey(),[...document.querySelectorAll('#homeModules > [data-module]')].map(e=>e.dataset.module))}
function finish(){clearTimeout(timer);if(dragging){dragging.classList.remove('moving');persist();document.querySelector('#homeReorderHint').textContent='Layout saved.'}dragging=null;start=null}
function enhance(){
 const shell=document.querySelector('#app .workspace');if(!shell){document.querySelector('#completionFieldDock')?.remove();return}
 const home=document.querySelector('#fieldHome');shell.classList.toggle('field-home-active',!!home);
 const top=shell.querySelector('.top .row');
 if(top&&!document.querySelector('#themeToggle')){
 const b=document.createElement('button');b.id='themeToggle';b.className='btn secondary';b.type='button';
 const update=()=>{const dark=document.documentElement.dataset.theme==='dark';b.textContent=dark?'☀ Light':'☾ Dark';b.setAttribute('aria-label',dark?'Switch to light mode':'Switch to dark mode')};
 update();b.onclick=()=>{document.documentElement.dataset.theme=document.documentElement.dataset.theme==='dark'?'light':'dark';save('hamriq-theme',document.documentElement.dataset.theme);update()};top.prepend(b);
 }
 if(!home||home.dataset.ready)return;home.dataset.ready='1';
 const container=home.querySelector('#homeModules'),cards=[...container.children],saved=read(orderKey(),[]);
 saved.forEach(id=>{const card=cards.find(e=>e.dataset.module===id);if(card)container.append(card)});
 cards.filter(e=>!saved.includes(e.dataset.module)).forEach(e=>container.append(e));
 home.querySelector('#homeCustomize').onclick=()=>{const editing=home.classList.toggle('arranging');home.querySelector('#homeCustomize').textContent=editing?'Done':'Customize';home.querySelector('#homeReorderHint').textContent=editing?'Drag any card, or tap ↑ / ↓ to reorder.':'Your layout saves automatically.'};
 cards.forEach(card=>{
 const handle=card.querySelector('.module-handle');
 const controls=document.createElement('div');controls.className='module-move-controls';
 for(const [direction,label] of [['up','Move up'],['down','Move down']]){
  const b=document.createElement('button');b.type='button';b.textContent=direction==='up'?'↑':'↓';b.setAttribute('aria-label',label+' '+card.querySelector('h3').textContent);
  b.onclick=e=>{e.stopPropagation();const sibling=direction==='up'?card.previousElementSibling:card.nextElementSibling;if(!sibling)return;if(direction==='up')container.insertBefore(card,sibling);else container.insertBefore(sibling,card);persist();home.querySelector('#homeReorderHint').textContent='Layout saved.'};
  controls.append(b);
 }
 card.querySelector('header').append(controls);
 card.addEventListener('pointerdown',e=>{
  if(e.button!==0)return;
  const onHandle=!!e.target.closest('.module-handle');
  if(!onHandle&&(!home.classList.contains('arranging')||e.target.closest('button,a,input,select,textarea')))return;
  clearTimeout(timer);start={x:e.clientX,y:e.clientY};
  const begin=()=>{dragging=card;card.classList.add('moving');card.setPointerCapture(e.pointerId);home.querySelector('#homeReorderHint').textContent='Drag up or down, then release to save.'};
  if(home.classList.contains('arranging'))begin();else timer=setTimeout(begin,350);
 });
 card.addEventListener('pointermove',e=>{
  if(!dragging){if(start&&Math.hypot(e.clientX-start.x,e.clientY-start.y)>12)clearTimeout(timer);return}
  if(dragging!==card)return;e.preventDefault();
  // Use card geometry, not the element under the finger: pointer capture and overlays cannot hide the drop target.
  const others=[...container.children].filter(el=>el!==dragging);
  const target=others.find(el=>e.clientY<el.getBoundingClientRect().top+el.getBoundingClientRect().height/2);
  const currentNext=dragging.nextElementSibling;
  if(target!==currentNext)container.insertBefore(dragging,target||null);
  if(e.clientY<100)window.scrollBy(0,-12);else if(e.clientY>innerHeight-120)window.scrollBy(0,12);
 });
 card.addEventListener('pointerup',finish);card.addEventListener('pointercancel',finish);card.addEventListener('lostpointercapture',finish);
 handle.addEventListener('keydown',e=>{if(e.key==='ArrowUp'||e.key==='ArrowDown'){e.preventDefault();const sibling=e.key==='ArrowUp'?card.previousElementSibling:card.nextElementSibling;if(sibling){if(e.key==='ArrowUp')container.insertBefore(card,sibling);else container.insertBefore(sibling,card);persist();handle.focus()}}});
 });
}

new MutationObserver(enhance).observe(document.documentElement,{childList:true,subtree:true});
enhance();
