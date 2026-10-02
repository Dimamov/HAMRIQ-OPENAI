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
 home.querySelector('#homeCustomize').onclick=()=>{const editing=home.classList.toggle('arranging');home.querySelector('#homeCustomize').textContent=editing?'Done':'Arrange cards';home.querySelector('#homeReorderHint').textContent=editing?'Drag a handle, or use its arrow keys to move a card.':'Your layout saves automatically.'};
 // Long press on non-interactive card content; normal scrolling cancels the hold.
 cards.forEach(card=>{
 card.addEventListener('touchstart',e=>{
  if(e.touches.length!==1||e.target.closest('button,a,input,select,textarea'))return;
  clearTimeout(timer);start={x:e.touches[0].clientX,y:e.touches[0].clientY};
  timer=setTimeout(()=>{dragging=card;card.classList.add('moving');home.querySelector('#homeReorderHint').textContent='Move up or down, then release to save.'},400);
 },{passive:true});
 card.addEventListener('touchmove',e=>{
  const point=e.touches[0];if(!point)return;
  if(!dragging){if(start&&Math.hypot(point.clientX-start.x,point.clientY-start.y)>12)clearTimeout(timer);return}
  e.preventDefault();
  const target=document.elementFromPoint(point.clientX,point.clientY)?.closest('#homeModules > [data-module]');
  if(target&&target!==dragging){const r=target.getBoundingClientRect();container.insertBefore(dragging,point.clientY<r.top+r.height/2?target:target.nextSibling)}
  if(point.clientY<100)window.scrollBy(0,-12);else if(point.clientY>innerHeight-120)window.scrollBy(0,12);
 },{passive:false});
 card.addEventListener('touchend',finish);card.addEventListener('touchcancel',finish);
 });
 home.querySelectorAll('.module-handle').forEach(handle=>{
 handle.addEventListener('pointerdown',e=>{if(e.button!==0)return;start={x:e.clientX,y:e.clientY};const card=handle.closest('[data-module]');timer=setTimeout(()=>{dragging=card;card.classList.add('moving');handle.setPointerCapture(e.pointerId);home.querySelector('#homeReorderHint').textContent='Move up or down, then release to save.'},home.classList.contains('arranging')?0:350)});
 handle.addEventListener('pointermove',e=>{if(!dragging){if(start&&Math.hypot(e.clientX-start.x,e.clientY-start.y)>12)clearTimeout(timer);return}e.preventDefault();const target=document.elementFromPoint(e.clientX,e.clientY)?.closest('#homeModules > [data-module]');if(target&&target!==dragging){const r=target.getBoundingClientRect();container.insertBefore(dragging,e.clientY<r.top+r.height/2?target:target.nextSibling)}if(e.clientY<100)window.scrollBy(0,-12);else if(e.clientY>innerHeight-120)window.scrollBy(0,12)});
 handle.addEventListener('pointerup',finish);handle.addEventListener('pointercancel',finish);
 handle.addEventListener('keydown',e=>{const card=handle.closest('[data-module]');if(e.key==='ArrowUp'&&card.previousElementSibling){e.preventDefault();container.insertBefore(card,card.previousElementSibling);persist();handle.focus()}if(e.key==='ArrowDown'&&card.nextElementSibling){e.preventDefault();container.insertBefore(card.nextElementSibling,card);persist();handle.focus()}});
 });
}
new MutationObserver(enhance).observe(document.documentElement,{childList:true,subtree:true});
enhance();
