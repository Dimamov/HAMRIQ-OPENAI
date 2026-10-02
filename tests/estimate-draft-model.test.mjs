import test from 'node:test';
import assert from 'node:assert/strict';
import {buildPriceLines,compareCarrier} from '../src/workspace/estimate-draft-model.mjs';
const prices=[{code:'SHINGLE',name:'Shingle',unit:'SQ',price:125},{code:'RIDGE',name:'Ridge',unit:'LF',price:4.5}];
test('measurement sources build itemized prices with cents',()=>{const lines=buildPriceLines([{code:'SHINGLE',source:'roofSquaresWaste'},{code:'RIDGE',source:'ridgeLf'}],{roofSquaresWaste:33.6,ridgeLf:120},prices);assert.equal(lines[0].amount,4200);assert.equal(lines[1].amount,540);});
test('empty, unknown, duplicate, zero and negative quantities are blocked',()=>{for(const items of [[],[{code:'UNKNOWN',source:'manual',quantity:1}],[{code:'RIDGE',source:'manual',quantity:0}],[{code:'RIDGE',source:'manual',quantity:-1}],[{code:'RIDGE',source:'manual',quantity:1},{code:'RIDGE',source:'manual',quantity:1}]])assert.throws(()=>buildPriceLines(items,{},prices));});
test('carrier comparison flags missing scope and quantity or price shortfalls',()=>{const expected=buildPriceLines([{code:'SHINGLE',source:'manual',quantity:30},{code:'RIDGE',source:'manual',quantity:120}],{},prices);const result=compareCarrier(expected,'shingle, 25, 120');assert.equal(result.total,1290);assert.equal(result.lines[1].carrier,null);assert.deepEqual(result.unmatched,[]);});
test('carrier duplicates and invalid rows fail; unmatched items require mapping',()=>{for(const text of ['', 'RIDGE, 2', 'RIDGE, -1, 5','RIDGE, , 5','RIDGE, 2, 5\nridge, 1, 5'])assert.throws(()=>compareCarrier([],text));assert.deepEqual(compareCarrier([], 'OTHER, 1, 20').unmatched,['other']);});
test('carrier overpayment produces no negative supplemental amount',()=>{assert.equal(compareCarrier([{code:'RIDGE',amount:10}], 'RIDGE, 2, 20').total,0);});
