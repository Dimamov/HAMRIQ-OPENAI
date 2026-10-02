export function quantityFor(source, measurements) {
  const value = Number(measurements[source]);
  if (!Number.isFinite(value) || value < 0) throw Error('Enter valid non-negative measurements.');
  if (source !== 'roofSquaresWaste') return value;
  return value;
}
export function buildPriceLines(items, measurements, prices) {
  if (!items.length) throw Error('Add at least one scope item.');
  const codes = new Set();
  return items.map(item => {
    const price = prices.find(p => p.code === item.code);
    if (!price) throw Error('Choose a current price-book item.');
    if (codes.has(item.code)) throw Error('Combine duplicate price codes into one scope line.');
    codes.add(item.code);
    const quantity = item.source === 'manual' ? Number(item.quantity) : quantityFor(item.source, measurements);
    if (!Number.isFinite(quantity) || quantity <= 0) throw Error('Each scope item needs a positive quantity.');
    if (!Number.isFinite(Number(price.price)) || Number(price.price) < 0) throw Error('Price-book item has invalid pricing.');
    return {code:price.code,name:price.name,unit:price.unit,quantity,unit_price:Number(price.price),amount:Math.round(quantity*Number(price.price)*100)/100};
  });
}
export function compareCarrier(expected, text) {
  const carrier = new Map();
  for (const row of text.split('\n').filter(s=>s.trim())) {
    const parts=row.split(',').map(s=>s.trim());
    const [code,q,p]=parts;
    if (parts.length!==3 || !code || !q || !p || !Number.isFinite(Number(q)) || !Number.isFinite(Number(p)) || Number(q)<0 || Number(p)<0) throw Error('Carrier lines must be CODE, QUANTITY, UNIT PRICE.');
    const key=code.toLowerCase();
    if(carrier.has(key)) throw Error('Combine duplicate carrier codes first.');
    carrier.set(key,{quantity:Number(q),unit_price:Number(p),amount:Math.round(Number(q)*Number(p)*100)/100});
  }
  if(!carrier.size) throw Error('Enter the carrier line items before comparing.');
  const lines=expected.map(e=>{
    const c=carrier.get(e.code.toLowerCase());
    return {...e,carrier:c||null,gap:Math.max(0,Math.round((e.amount-(c?.amount||0))*100)/100)};
  });
  const expectedCodes=new Set(expected.map(e=>e.code.toLowerCase()));
  return {lines,total:Math.round(lines.reduce((s,l)=>s+l.gap,0)*100)/100,unmatched:[...carrier.keys()].filter(k=>!expectedCodes.has(k))};
}
