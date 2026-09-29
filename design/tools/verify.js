// Rentbutik screen verifier — paste as the `code` body of a use_figma call.
// Set SCREEN_ID before running. Returns a structured violation report.
// Encodes CHECKLIST.md as executable rules.

// Runs over a whole lane at once: set LANE_ID to a Section id, or SCREEN_IDS
// to an explicit list. Returns one report per screen plus a lane summary.
const LANE_ID = '__LANE_ID__';
const SCREEN_IDS = __SCREEN_IDS__;

// Selecting screens: a 402x874 frame is NOT necessarily a screen — full-bleed
// Map children match the same dimensions. Require a SECTION parent:
//   page.findAll(n => n.type === 'FRAME' && Math.round(n.width) === 402
//                     && Math.round(n.height) === 874
//                     && n.parent && n.parent.type === 'SECTION')

let targets = [];
if (LANE_ID && LANE_ID.indexOf('__') !== 0) {
  const lane = await figma.getNodeByIdAsync(LANE_ID);
  if (!lane) throw new Error('lane not found: ' + LANE_ID);
  await figma.setCurrentPageAsync(lane.parent);
  targets = lane.children.filter(c => c.type === 'FRAME' &&
    Math.round(c.width) === 402 && Math.round(c.height) === 874);
} else {
  for (const id of SCREEN_IDS) {
    const n = await figma.getNodeByIdAsync(id);
    if (!n) throw new Error('screen not found: ' + id);
    targets.push(n);
  }
  if (targets.length) await figma.setCurrentPageAsync(targets[0].parent.parent);
}

const REPORTS = [];
for (const screen of targets) {

const V = [];
const add = (rule, sev, detail, id) => V.push({ rule, sev, detail, id });

// --- 1. Geometry -------------------------------------------------------
if (Math.round(screen.width) !== 402 || Math.round(screen.height) !== 874) {
  add('geometry/device', 'HIGH',
      'expected 402x874 (iPhone 18 Pro), got ' +
      Math.round(screen.width) + 'x' + Math.round(screen.height), screen.id);
}

const all = screen.findAll(() => true);

// --- 2. Naming ---------------------------------------------------------
const DEFAULT_NAME = /^(Frame|Vector|Rectangle|Ellipse|Group|Line|Polygon|Star|Component)\s*\d*$/i;
const ALLOW = /^(spacer-\d+|push)$/;
for (const n of all) {
  if (DEFAULT_NAME.test(n.name) && !ALLOW.test(n.name)) {
    add('naming/default', 'MED', 'default layer name "' + n.name + '"', n.id);
  }
}

// --- 3. Tokens: every visible SOLID fill must be variable-bound ---------
function checkPaints(n, prop) {
  const arr = n[prop];
  if (!Array.isArray(arr)) return;
  for (const p of arr) {
    if (p.type !== 'SOLID' || p.visible === false) continue;
    const bound = p.boundVariables && p.boundVariables.color;
    if (!bound) {
      const c = p.color;
      const hex = '#' + [c.r, c.g, c.b].map(v =>
        ('0' + Math.round(v * 255).toString(16)).slice(-2)).join('');
      add('tokens/raw-' + prop, 'HIGH', 'unbound ' + prop + ' ' + hex + ' on "' + n.name + '"', n.id);
    }
  }
}
for (const n of all) {
  if ('fills' in n) checkPaints(n, 'fills');
  if ('strokes' in n) checkPaints(n, 'strokes');
}

// --- 4. Type: every text node must use a Type/* style -------------------
const styleCache = {};
for (const n of all) {
  if (n.type !== 'TEXT') continue;
  const sid = n.textStyleId;
  if (!sid || typeof sid !== 'string') {
    add('type/no-style', 'HIGH', 'text "' + n.characters.slice(0, 24) + '" has no text style', n.id);
    continue;
  }
  if (!(sid in styleCache)) {
    const st = await figma.getStyleByIdAsync(sid);
    styleCache[sid] = st ? st.name : null;
  }
  const nm = styleCache[sid];
  if (nm && nm.indexOf('Type/') !== 0) {
    add('type/wrong-ramp', 'MED', 'text uses "' + nm + '" not a Type/* style', n.id);
  }
  if (Math.round(n.width) === 0 || Math.round(n.height) <= 15 && n.fontSize > 13) {
    add('type/collapsed', 'HIGH',
        'text "' + n.characters.slice(0, 20) + '" measures ' +
        Math.round(n.width) + 'x' + Math.round(n.height) + ' — font did not render', n.id);
  }
}

// --- 5. Tab bar clearance (RULE B8) ------------------------------------
// The rule is the OUTCOME — content must not run under the tab bar — not the
// mechanism. A spacer-96 node and a 96pt bottom padding both satisfy it.
const hasTabBar = !!screen.findOne(n => n.name === 'Tab bar');
if (hasTabBar) {
  const spacer = screen.findOne(n => n.name === 'spacer-96');
  const padded = screen.findOne(n => 'paddingBottom' in n && n.paddingBottom >= 96);
  if (!spacer && !padded) {
    add('layout/tab-clearance', 'HIGH',
        'screen has a Tab bar but no 96pt clearance (spacer-96 node or >=96 bottom padding) — content will run under it', screen.id);
  }
}

// --- 6. Contrast: never white/light text on a gold fill (RULE B1) ------
const GOLD = ['brand/solid', 'brand/amber', 'brand/honey', 'brand/bronze',
              'brand/gradient-start', 'brand/gradient-mid', 'brand/gradient-end'];
async function fillTokenName(n) {
  if (!('fills' in n) || !Array.isArray(n.fills)) return null;
  for (const p of n.fills) {
    const b = p.boundVariables && p.boundVariables.color;
    if (!b) continue;
    const v = await figma.variables.getVariableByIdAsync(b.id);
    if (v) return v.name;
  }
  return null;
}
for (const n of all) {
  if (n.type !== 'TEXT') continue;
  let p = n.parent, goldAncestor = null;
  for (let i = 0; i < 4 && p && p.type !== 'PAGE'; i++, p = p.parent) {
    const t = await fillTokenName(p);
    if (t && GOLD.indexOf(t) >= 0) { goldAncestor = t; break; }
  }
  if (goldAncestor) {
    const own = await fillTokenName(n);
    if (own !== 'text/on-gold') {
      add('contrast/white-on-gold', 'HIGH',
          'text on ' + goldAncestor + ' uses "' + own + '" — must be text/on-gold (#14161A)', n.id);
    }
  }
}

// --- 7. Icons must be SF Symbol component instances ---------------------
for (const n of all) {
  if (n.name !== 'Icon slot') continue;
  const kids = ('children' in n) ? n.children : [];
  if (!kids.length) { add('icons/empty-slot', 'MED', 'empty icon slot', n.id); continue; }
  const inst = kids.find(k => k.type === 'INSTANCE');
  if (!inst) { add('icons/not-symbol', 'MED', 'icon slot has no SF Symbol instance', n.id); continue; }
  const mc = await inst.getMainComponentAsync();
  if (!mc || mc.name.indexOf('Icon / ') !== 0) {
    add('icons/not-symbol', 'MED',
        'icon is "' + (mc ? mc.name : '?') + '", not an Icon / <sf.symbol> component', n.id);
  }
}

// --- 8. Screen must live inside its lane -------------------------------
// Section children are RELATIVE; only absoluteTransform tells the truth.
const abs = screen.absoluteTransform[1][2];
const sec = (screen.parent && screen.parent.type === 'SECTION') ? screen.parent : null;
if (!sec) add('scheme/not-in-lane', 'HIGH', 'screen is not inside a lane Section', screen.id);
else if (abs < sec.y - 1 || abs + 874 > sec.y + sec.height + 1)
  add('scheme/outside-lane', 'HIGH', 'absolute y ' + Math.round(abs) +
      ' falls outside lane ' + sec.name, screen.id);

// --- Report ------------------------------------------------------------
const bySev = { HIGH: 0, MED: 0, LOW: 0 };
for (const v of V) bySev[v.sev]++;
const byRule = {};
for (const v of V) byRule[v.rule] = (byRule[v.rule] || 0) + 1;

REPORTS.push({
  screen: screen.name,
  id: screen.id,
  size: Math.round(screen.width) + 'x' + Math.round(screen.height),
  nodes: all.length,
  PASS: V.length === 0,
  counts: bySev,
  byRule,
  violations: V.slice(0, 40)
});

} // end per-screen loop

const failing = REPORTS.filter(r => !r.PASS);
return {
  screens: REPORTS.length,
  passing: REPORTS.length - failing.length,
  PASS: failing.length === 0,
  summary: REPORTS.map(r => r.screen + ' :: ' + (r.PASS ? 'PASS' : 'FAIL ' + JSON.stringify(r.byRule))),
  failing
};

/* ---------------------------------------------------------------------------
   ICON INTEGRITY — run once over the SF Symbols library, not per screen.

   An SF Symbol with an inner cutout (checkmark.seal.fill, person.crop.circle.fill,
   exclamationmark.triangle.fill, bolt.car.fill …) arrives from SVG as SEVERAL
   separate <path> elements. Filling each one the same colour renders a solid
   BLOB — the checkmark, the person, the exclamation mark all disappear.

   They must be ONE vector whose vectorPaths use windingRule 'EVENODD'.

   const lib = await figma.getNodeByIdAsync('4021:2');
   for (const c of lib.children) {
     if (c.type !== 'COMPONENT') continue;
     const vecs = c.findAll(n => n.type === 'VECTOR');
     if (vecs.length > 1) report(c.name, 'separate vectors — cutouts will not render');
     else if (vecs[0].vectorPaths.length > 1 &&
              vecs[0].vectorPaths.some(p => p.windingRule !== 'EVENODD'))
       report(c.name, 'multi subpath without EVENODD');
   }

   Build icons as a SINGLE path with fill-rule="evenodd":
     '<path fill-rule="evenodd" clip-rule="evenodd" d="' + allSubpaths.join(' ') + '"/>'

   NOTE: rebuilding a component RESETS per-instance colour overrides.
   Re-apply them by context afterwards (tab active/inactive, nav, on-gradient,
   destructive states).
--------------------------------------------------------------------------- */

