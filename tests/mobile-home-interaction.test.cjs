const vm=require('node:vm'),fs=require('node:fs'),assert=require('node:assert/strict');
let timers=new Map(),serial=0,saved=new Map(),hit;
class El{
 constructor(id){this.dataset={module:id};this.events={};this.classList={add(){},remove(){},contains(){return false},toggle(){return false}};this.textContent='';}
 addEventListener(n,fn){this.events[n]=fn}
 closest(s){return s.includes('data-module')?this:null}
 getBoundingClientRect(){return {top:200,height:100}}
}
const cards=['next','jobs','followups','reviews'].map(id=>new El(id));
const container={children:cards,append(e){this.insertBefore(e,null)},insertBefore(e,b){const i=cards.indexOf(e);if(i>=0)cards.splice(i,1);const j=b?cards.indexOf(b):cards.length;cards.splice(j,0,e)}};
for(const e of cards){Object.defineProperty(e,'nextSibling',{get(){return cards[cards.indexOf(e)+1]||null}})}
const hint=new El(),custom=new El(),home=new El();
home.dataset={};home.querySelector=s=>s==='#homeModules'?container:s==='#homeCustomize'?custom:hint;home.querySelectorAll=()=>[];
const shell=new El();shell.querySelector=()=>null;
const doc={documentElement:{dataset:{}},querySelector(s){return s==='#app .workspace'?shell:s==='#fieldHome'?home:s==='#homeReorderHint'?hint:s==='.page-heading .eyebrow'?{textContent:'Owner'}:null},querySelectorAll(){return cards},elementFromPoint(){return hit}};
const context={document:doc,localStorage:{getItem:k=>saved.get(k),setItem:(k,v)=>saved.set(k,v)},location:{host:'test'},matchMedia:()=>({matches:false}),MutationObserver:class{observe(){}},setTimeout:fn=>{timers.set(++serial,fn);return serial},clearTimeout:id=>timers.delete(id),window:{scrollBy(){}},innerHeight:800};
vm.runInNewContext(fs.readFileSync(require('node:path').join(__dirname,'../src/workspace/mobile-home.mjs'),'utf8'),context);
const target={closest:()=>null};
const touch=(x,y)=>({target,touches:[{clientX:x,clientY:y}],preventDefault(){this.prevented=true}});
const flush=()=>{const all=[...timers.values()];timers.clear();all.forEach(fn=>fn())};
let jobs=cards.find(e=>e.dataset.module==='jobs');
jobs.events.touchstart(touch(100,250));flush();hit=cards[0];const move=touch(100,210);jobs.events.touchmove(move);jobs.events.touchend();
assert.equal(cards[0].dataset.module,'jobs');assert.equal(move.prevented,true);assert.equal(hint.textContent,'Layout saved.');assert([...saved.values()].some(s=>s.includes('jobs')));
let next=cards.find(e=>e.dataset.module==='next');
next.events.touchstart(touch(100,250));next.events.touchmove(touch(100,280));flush();hit=cards[0];const scrolling=touch(100,210);next.events.touchmove(scrolling);next.events.touchend();assert.equal(scrolling.prevented,undefined);assert.equal(cards[0].dataset.module,'jobs');
next.events.touchstart({target:{closest:()=>({})},touches:[{clientX:100,clientY:250}]});assert.equal(timers.size,0);
console.log('PASS: long press reorder, saved order, scroll cancellation, interactive target exclusion');
