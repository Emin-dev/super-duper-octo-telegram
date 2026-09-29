// Rentbutik spec exporter — paste as the `code` body of a use_figma call.
// Set LANE_IDS to the Section ids you want. Returns { laneName: markdown }.
//
// Why this exists: an agent without Figma access still has to build the app
// correctly. This dumps every screen as its real node tree with the actual
// copy, text style, colour token, SF Symbol and geometry — the design as text.
//
// Tab bars are collapsed to one line naming the selected tab; the full tab-bar
// structure is identical on every screen and is documented once in SPEC/README.md.

const LANE_IDS = __LANE_IDS__;

const page = await figma.getNodeByIdAsync('4007:6935');
await figma.setCurrentPageAsync(page);

const varCache = {}, styleCache = {};
async function tok(id) {
  if (!(id in varCache)) { const v = await figma.variables.getVariableByIdAsync(id); varCache[id] = v ? v.name : id; }
  return varCache[id];
}
async function sty(id) {
  if (!id || typeof id !== 'string') return null;
  if (!(id in styleCache)) { const s = await figma.getStyleByIdAsync(id); styleCache[id] = s ? s.name : null; }
  return styleCache[id];
}
async function fillTok(n) {
  if (!n || !('fills' in n) || !Array.isArray(n.fills)) return null;
  for (const p of n.fills) {
    if (p.visible === false) continue;
    const b = p.boundVariables && p.boundVariables.color;
    if (b) return await tok(b.id);
    if (p.type && p.type.indexOf('GRADIENT') === 0) return 'gradient';
  }
  return null;
}

// The selected tab is the one whose label is text/gold.
async function tabLine(tb, pad) {
  let selected = '?';
  for (const t of tb.children) {
    const label = t.findOne(n => n.type === 'TEXT');
    if (label && (await fillTok(label)) === 'text/gold') selected = label.characters;
  }
  return pad + 'Tab bar  [' + selected + ' selected]';
}

async function line(n, d, out) {
  const pad = '  '.repeat(d);
  if (n.name === 'Tab bar') { out.push(await tabLine(n, pad)); return; }

  if (n.type === 'TEXT') {
    const st = await sty(n.textStyleId), f = await fillTok(n);
    out.push(pad + '"' + n.characters.replace(/\n/g, ' / ') + '"' + (st ? '  ' + st : '') + (f ? '  ' + f : ''));
    return;
  }
  if (n.type === 'INSTANCE') {
    const mc = await n.getMainComponentAsync();
    const f = await fillTok(n.findOne(x => x.type === 'VECTOR')) || await fillTok(n);
    out.push(pad + '<' + (mc ? mc.name : 'instance') + '>' + (f ? '  ' + f : ''));
    return;
  }
  // an Icon slot wrapping a single instance adds nothing — skip the wrapper
  if (n.name === 'Icon slot' && 'children' in n && n.children.length === 1 && n.children[0].type === 'INSTANCE') {
    await line(n.children[0], d, out);
    return;
  }
  if (/^spacer-/.test(n.name)) { out.push(pad + n.name); return; }

  const bits = [];
  if ('layoutMode' in n && n.layoutMode !== 'NONE') bits.push(n.layoutMode.toLowerCase());
  const f = await fillTok(n);
  if (f) bits.push(f);
  if ('cornerRadius' in n && typeof n.cornerRadius === 'number' && n.cornerRadius) bits.push('r' + Math.round(n.cornerRadius));
  bits.push(Math.round(n.width) + 'x' + Math.round(n.height));
  out.push(pad + n.name + '  [' + bits.join(' ') + ']');

  if ('children' in n && d < 5) for (const c of n.children) await line(c, d + 1, out);
}

const RESULT = {};
for (const laneId of LANE_IDS) {
  const lane = await figma.getNodeByIdAsync(laneId);
  const out = ['# ' + lane.name, ''];
  const note = lane.children.find(c => /^Lane note/.test(c.name));
  if (note) out.push('> ' + note.characters.replace(/\n/g, ' '), '');
  const screens = lane.children.filter(c => c.type === 'FRAME' &&
    Math.round(c.width) === 402 && Math.round(c.height) === 874);
  for (const s of screens) {
    out.push('## ' + s.name + '  `' + s.id + '`', '', '```');
    for (const c of s.children) await line(c, 0, out);
    out.push('```', '');
  }
  RESULT[lane.name] = out.join('\n');
}
return RESULT;

