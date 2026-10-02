// ============================================================================
// pen149.scad — parametric 3-piece fountain pen, V2 layout (MASTER SOURCE)
//
// A Montblanc 149-style pen: section (grips a Jinhao #6 nib unit),
// barrel (body), cap (threads onto the barrel, not the section).
//
// HOW TO USE (OpenSCAD on your Mac):
//   1. Set MODE / PART below, press F5 for a fast preview.
//   2. PART="assembly" shows all three parts fitted together.
//      SECTION_VIEW=true cuts the assembly in half so you can inspect how
//      the threads engage — this is the visual thread-fit test.
//   3. F6 renders, then File > Export > Export as STL for the slicer.
//      (ASCII STL is the default export and what we want.)
//
// JOINTS (all validated: min radial gap 0.450mm in both modes)
//   J1  nib unit -> section     M8 x 1.0 single-start, z=13-18.8 (interior)
//   J2  section -> barrel       11.0 x 1.5 single-start, section z=22-30
//   J4  cap -> barrel           15.0 x 2.0 TRIPLE-start, barrel z=8-16
//       (closes in ~1.5 turns)
//   Friction post (2026-09-26, per Brian — no screw post): the barrel's
//     smooth rear post (z=58-86, r=6.92) slides through the cap mouth and
//     wedges into the cap's tapered bore for a pressure fit. The cap bore
//     tapers 7.30 @ z=8 -> 6.90 @ z=24 -> 6.70 @ z=66.5 (V3).
//
// BARREL (2026-09-26): smooth single-taper exterior — the old mid-body bulge
// (r=8.05 @ z=30) and the hard step at z=16 are gone. One continuous line:
// 15.0mm at the J4 band tapering gently to 13.1mm at z=78.
//
// THREAD MATH (matches the validated Python master, make_pen.py):
//   Trapezoidal ACME-like profile, phase = (z/p - starts*theta/360) mod 1.
//   Male teeth 0.55 pitch wide; female grooves cut from a 0.65-wide tooth,
//   giving deterministic axial clearance. Female = male + radial CLEAR,
//   sampled in the male's frame at the assembled position, so threads mesh
//   by construction. NOTE: OpenSCAD trig uses degrees.
//
// MODES:
//   "prototype" (FDM): CLEAR = 0.45mm radial (0.25 + 0.20 FDM shrinkage comp)
//   "final" (resin):   CLEAR = 0.45mm radial (resin prints truer, no comp).
//   (2026-09-26: "final" was 0.20 — WRONG. The assembly-path simulation in
//   make_pen.py proves 0.20 jams the J2 joint (-0.550mm interference); 0.45
//   is the validated clearance for both processes.)
// ============================================================================

// ---------------- user controls ----------------
MODE = "prototype";   // "prototype" | "final"
PART = "section_ballpoint";     // "section" | "section_flare" | "section_ballpoint" | "barrel" | "cap" | "cap_v2" | "cap_oct" | "cap_fluted" | "cap_square" | "cap_pisa" | "coupon" | "plug" | "assembly"
DETAIL = 224;         // facets around the circumference (96 = fast preview)
SECTION_VIEW = false; // true with PART="assembly": cutaway thread-fit view
THREAD_DIV = 20;      // z-samples per thread pitch (fidelity, keep at 20)
// (2026-09-26: one barrel for both caps — the DOME selector is retired.)
// (2026-09-26: "short" barrel variant per Brian — 93mm, more elegant point.)
BARREL = "short";      // "short" (93mm, continuous taper) | "std" (100mm, retired)

// ---------------- thread math ----------------
// 2026-09-26: octagon support — regular octagon radius at angle t (degrees),
// rf = center-to-flat distance. Flats centered at 0°, 45°, 90°, ...
function oct_r(rf, t) = rf / cos((t % 45) - 22.5);
// 2026-09-29: fluted-cap support — 14 concave longitudinal flutes,
// Parker Duofold / fluted-column style. rb = V3 body radius at station z,
// t = angle in degrees. C1-smooth runouts ease the flutes in above the
// mouth/gold band (z=8-14) and out before the crown (z=66-72).
// (matches make_pen.py flute_env/flute_r exactly)
function flute_env(z) = sstep(8,14,z) * (1 - sstep(66,72,z));
function flute_r(rb, z, t) = rb - 0.6*flute_env(z)*(0.5 - 0.5*cos(14*t));
function sstep(a,b,x) = let(t = min(max((x-a)/(b-a), 0), 1)) t*t*(3-2*t);
// 2026-09-29: square-cap support — squarish cross-section with highly
// chamfered 45-degree corners, Faber-Castell e-motion style. a =
// center-to-flat distance (follows the V3 body taper); cut = chamfer cut
// along the square edge (face width = cut*sqrt(2)). Flats centered at
// 0, 90, ... degrees; chamfer faces at 45 degrees. t = angle in degrees.
// sq_cap_r blends the V3 body radius into the chamfered square over z=8-14
// (C1 smoothstep, above the mouth band and J4 zone); full square above.
// (matches make_pen.py square_chamfer_r/sq_env/square_cap_r exactly)
function sq_chamfer_r(a, cut, t) =
  let(phi = min(t % 90, 90 - (t % 90)),
      p1 = atan((a-cut)/a))
  phi <= p1 ? a/cos(phi) : (2*a-cut)/(cos(phi)+sin(phi));
function sq_env(z) = sstep(8,14,z);
function sq_cap_r(a, z, t) = a + (sq_chamfer_r(a, 2.5, t) - a)*sq_env(z);
// 2026-09-30: pisa-cap support — abstracted Leaning Tower of Pisa: 5 raised
// ring beads (string courses; the base bead slightly more pronounced) +
// 32 shallow sinusoidal ribs suggesting the colonnades. All additive over
// the V3 body; t = angle in degrees. Ribs run continuously under the beads
// (phase-continuous, beads sit on top — no steps).
// (matches make_pen.py pisa_bump/pisa_rings/pisa_rib_env/pisa_r exactly)
function pisa_bump(z, zc, w, h) =
  abs(z-zc) >= w/2 ? 0 : h*0.5*(1+cos(360*(z-zc)/w));
function pisa_rings(z) =
  pisa_bump(z,16,1.8,0.5) + pisa_bump(z,28,1.4,0.4) + pisa_bump(z,40,1.4,0.4)
  + pisa_bump(z,52,1.4,0.4) + pisa_bump(z,64,1.4,0.4);
function pisa_rib_env(z) = sstep(8,14,z) * (1 - sstep(66,72,z));
function pisa_r(rb, z, t) =
  rb + pisa_rings(z) + 0.25*pisa_rib_env(z)*(0.5 - 0.5*cos(32*t));

function trap(ph, flat=0.55, flank=0.12) =
  let(c0 = 0.5-flat/2, c1 = 0.5+flat/2)
  ph < c0-flank ? 0 :
  ph < c0 ? sstep(c0-flank, c0, ph) :
  ph < c1 ? 1 :
  ph < c1+flank ? 1 - sstep(c1, c1+flank, ph) : 0;

function thread_r(od, pitch, starts, h, z0, z1, th, z, flat=0.55, runout=0.6) =
  let(rr = od/2 - h,
      ro = runout*pitch,
      ph = (((z/pitch - starts*th/360) % 1) + 1) % 1,
      taper = sstep(z0, z0+ro, z) * (1 - sstep(z1-ro, z1, z)))
  rr + h*trap(ph, flat)*taper;

// ---------------- joints ----------------
CLEAR = 0.45; // J1 nib thread (proven "It worked" — do not touch)
CLEAR_J4 = 0.50; // 2026-09-26: generous (match J2) for print variation

function J1f(th,z) = thread_r(8.0, 1.0, 1, 0.50, 13.0, 18.8, th, z, 0.65) + CLEAR;
// 2026-09-26 (per Brian): J2m 0.05 smaller — the printed section was a touch
// tight; gives 0.50 clearance in the (already printed) 0.45 barrels.
// 2026-09-26 (per Brian): J2m tooth narrowed 0.55→0.45 — section still wasn't
// screwing in smoothly; narrower teeth give more axial clearance for easier
// assembly. Barrel (J2f) unchanged.
function J2m(th,z) = thread_r(11.0, 1.5, 1, 0.75, 22.0, 30.0, th, z, 0.45) - 0.05;
function J2f(th,z) = thread_r(11.0, 1.5, 1, 0.75, 22.0, 30.0, th, z+22.0, 0.65) + CLEAR;
function J4m(th,z) = thread_r(15.0, 2.0, 3, 1.00, 8.0, 16.0, th, z, 0.55, 1.0);
// J4r REMOVED 2026-09-26: Brian nixed the threaded post — pressure fit instead.
// J4 female: FULL PROFILE to the mouth (like a real nut). Defined over
// [-2,10] so the runout tapers fall outside the sampled [0,8].
// (2026-09-25: a tapered female mouth JAMMED the cap on the barrel;
// the male's own 2mm runout is the lead-in. See make_pen.py.)
function J4f(th,z) = thread_r(15.0, 2.0, 3, 1.00, -2.0, 10.0, th, z, 0.65, 1.0) + CLEAR_J4;

function thread_fn(name, th, z) =
  name == "J1f" ? J1f(th,z) :
  name == "J2m" ? J2m(th,z) :
  name == "J2f" ? J2f(th,z) :
  name == "J4m" ? J4m(th,z) :
  name == "J4f" ? J4f(th,z) : undef;

// ---------------- stations: [z, radius] | [z, "thread"] | [z, "axis"] ----------------
function thread_stations(z0, z1, pitch, name) =
  let(n = max(2, ceil((z1-z0)/(pitch/THREAD_DIV) - 1e-9)))
  [for(k=[0:n]) [z0 + (z1-z0)*k/n, name]];

function thread_stations_rev(z0, z1, pitch, name) =
  let(fwd = thread_stations(z0, z1, pitch, name), m = len(fwd))
  [for(i=[m-1:-1:0]) fwd[i]];

function section_stations() = concat(
  // V2.1 (2026-09-25): 149-style grip — smooth concave sweep, no bulge/waist
  [[0.0,5.15],[2.0,5.35],[4.0,5.52],[6.0,5.66],
   [8.0,5.80],[10.0,5.94],[12.0,6.06],[14.0,6.18],
   [16.0,6.30],[18.0,6.40],[20.0,6.50],[22.0,6.60]],
  thread_stations(22.0, 30.0, 1.5, "J2m"),
  [[30.0,4.15],[21.5,4.15],[18.8,4.15]],
  thread_stations_rev(13.0, 18.8, 1.0, "J1f"),
  [[13.0,4.35],[4.5,4.35],[2.0,4.35],[0.0,4.30]]
);

function barrel_back_short() = [
  // 2026-09-26 (per Brian's sketch): smooth cubic-bezier taper —
  // no kink, elegant continuous curve. Posts 76.9% (V3)/77.4% (V2).
   [24.0,7.5000],
   [25.0,7.4338],
   [26.2,7.3706],
   [27.4,7.3104],
   [28.8,7.2529],
   [30.2,7.1982],
   [31.8,7.1461],
   [33.4,7.0965],
   [35.1,7.0494],
   [37.0,7.0045],
   [38.8,6.9619],
   [40.8,6.9214],
   [42.8,6.8829],
   [44.9,6.8463],
   [47.1,6.8115],
   [49.3,6.7784],
   [51.5,6.7470],
   [53.8,6.7170],
   [56.1,6.6885],
   [58.5,6.6613],
   [60.9,6.6352],
   [63.3,6.6103],
   [65.8,6.5864],
   [68.2,6.5634],
   [70.7,6.5412],
   [73.2,6.5198],
   [75.7,6.4989],
   [78.2,6.4785],
   [80.7,6.4585],
   [83.1,6.4388],
   [85.6,6.4194],
   [88.0,6.4000],
   [88.5,6.3324],
   [89.0,6.1376],
   [89.5,5.8156],
   [90.0,5.3664],
   [90.5,4.7900],
   [91.0,4.0864],
   [91.5,3.2556],
   [92.0,2.2976],
   [92.5,1.2124],
   [93.0,0.0000],
];

function barrel_stations() = concat(
  [[0.0,6.6],[0.6,6.7],[1.2,6.8],[4.0,6.8],[8.0,6.9]],
  thread_stations(8.0, 16.0, 2.0, "J4m"),
  [[18.0,6.95],[20.0,7.25],[22.0,7.43]],
  BARREL == "short" ? barrel_back_short() : barrel_back_std(),
  [[78.0,"axis"],[76.0,2.5],[74.0,4.0],[72.0,5.0],[12.0,5.0],[10.0,5.2]],
  thread_stations_rev(0.0, 8.0, 1.5, "J2f")
);

function barrel_back_std() = [
  // 2026-09-26: ONE barrel for both caps (per Brian) — classic 149-style
  // taper-wedge post. One smooth french curve: exponential drop from the
  // mid-body, a long gentle engagement taper (the wedge surface), then a
  // smooth sweep to a pointy 100mm tip. Posts to 75% of either cap's depth.
   [24.0,7.50],
   [26.0,7.352],[28.0,7.241],[30.0,7.158],[32.0,7.095],
   [34.0,7.048],[36.0,7.012],[38.0,6.986],[40.0,6.966],
   [42.0,6.951],[44.0,6.939],[46.0,6.931],[48.0,6.924],
   [52.0,6.919],[56.0,6.914],[60.0,6.908],[64.0,6.903],
   [68.0,6.897],[72.0,6.892],[76.0,6.887],[80.0,6.881],
   [84.0,6.876],[88.0,6.870],
   [90.0,6.850],[92.0,6.790],[94.0,6.650],[95.5,6.400],
   [97.0,5.950],[98.0,5.250],[98.8,4.300],[99.4,3.150],
   [99.8,1.800],[100.0,"axis"]];

function cap_stations() = concat(
  [[0.0,9.0],[2.0,9.0],[3.0,9.3],[5.0,9.3],
   [6.0,9.0],[10.0,9.0],[20.0,9.0],[30.0,8.95],[40.0,8.9],[50.0,8.85],
   [56.0,8.8],[62.0,8.8],[68.0,8.78],[74.0,8.75],
   // V2.1: 80mm long, shallow "almost flat" crown (6mm)
   [76.0,8.5],[77.5,7.9],[78.5,6.9],[79.3,5.4],[79.8,3.2],[80.0,"axis"],
   // 2026-09-26: bore re-tuned for the continuous-taper barrel (eased
   // bezier). Taper 0.024/mm from z=24 — binds at 76.9% of bore depth.
   // Mouth/J4/exterior unchanged.
   [76.5,"axis"],[75.5,2.0],[74.5,4.0],[72.5,5.5],[70.5,6.35],[68.5,6.60],
   [66.5,5.880],
   [64.0,5.940],[56.0,6.132],[48.0,6.324],[40.0,6.516],[32.0,6.708],[24.0,6.90],
   [20.0,7.00],[16.0,7.10],[12.0,7.20],[8.0,7.30]],
  thread_stations_rev(0.0, 8.0, 2.0, "J4f")
  // thread runs straight to the mouth face (no smaller flat annulus),
  // then wraparound closes to [0.0,9.0]
);

// Pisa cap (2026-09-30, per Brian): abstracted Leaning Tower of Pisa.
// Exterior only — the interior (bore + J4 female) is identical to
// cap_stations() so it screws on and posts exactly like the V3 (76.9%).
// Station r_base values baked from make_pen.py's PISA_STATIONS
// (identical params); mouth, gold band, and dome top are untouched.
// Clipless.
function cap_pisa_stations() = concat(
  [[0.0,9.0],[2.0,9.0],[3.0,9.3],[5.0,9.3],[6.0,9.0]],
  [[8.0,function(t) pisa_r(9.0,8.0,t)],
   [9.0,function(t) pisa_r(9.0,9.0,t)],
   [10.0,function(t) pisa_r(9.0,10.0,t)],
   [11.0,function(t) pisa_r(9.0,11.0,t)],
   [12.0,function(t) pisa_r(9.0,12.0,t)],
   [13.0,function(t) pisa_r(9.0,13.0,t)],
   [14.0,function(t) pisa_r(9.0,14.0,t)],
   [15.1,function(t) pisa_r(9.0,15.1,t)],
   [15.55,function(t) pisa_r(9.0,15.55,t)],
   [16.0,function(t) pisa_r(9.0,16.0,t)],
   [16.45,function(t) pisa_r(9.0,16.45,t)],
   [16.9,function(t) pisa_r(9.0,16.9,t)],
   [20.0,function(t) pisa_r(9.0,20.0,t)],
   [27.3,function(t) pisa_r(8.9635,27.3,t)],
   [27.65,function(t) pisa_r(8.9618,27.65,t)],
   [28.0,function(t) pisa_r(8.96,28.0,t)],
   [28.35,function(t) pisa_r(8.9582,28.35,t)],
   [28.7,function(t) pisa_r(8.9565,28.7,t)],
   [30.0,function(t) pisa_r(8.95,30.0,t)],
   [39.3,function(t) pisa_r(8.9035,39.3,t)],
   [39.65,function(t) pisa_r(8.9017,39.65,t)],
   [40.0,function(t) pisa_r(8.9,40.0,t)],
   [40.35,function(t) pisa_r(8.8983,40.35,t)],
   [40.7,function(t) pisa_r(8.8965,40.7,t)],
   [50.0,function(t) pisa_r(8.85,50.0,t)],
   [51.3,function(t) pisa_r(8.8392,51.3,t)],
   [51.65,function(t) pisa_r(8.8362,51.65,t)],
   [52.0,function(t) pisa_r(8.8333,52.0,t)],
   [52.35,function(t) pisa_r(8.8304,52.35,t)],
   [52.7,function(t) pisa_r(8.8275,52.7,t)],
   [56.0,function(t) pisa_r(8.8,56.0,t)],
   [62.0,function(t) pisa_r(8.8,62.0,t)],
   [63.3,function(t) pisa_r(8.7957,63.3,t)],
   [63.65,function(t) pisa_r(8.7945,63.65,t)],
   [64.0,function(t) pisa_r(8.7933,64.0,t)],
   [64.35,function(t) pisa_r(8.7922,64.35,t)],
   [64.7,function(t) pisa_r(8.791,64.7,t)],
   [66.0,function(t) pisa_r(8.7867,66.0,t)],
   [67.0,function(t) pisa_r(8.7833,67.0,t)],
   [68.0,function(t) pisa_r(8.78,68.0,t)],
   [69.0,function(t) pisa_r(8.775,69.0,t)],
   [70.0,function(t) pisa_r(8.77,70.0,t)],
   [71.0,function(t) pisa_r(8.765,71.0,t)],
   [72.0,function(t) pisa_r(8.76,72.0,t)],
   [74.0,function(t) pisa_r(8.75,74.0,t)]],
  [[76.0,8.5],[77.5,7.9],[78.5,6.9],[79.3,5.4],[79.8,3.2],[80.0,"axis"],
   // bore re-tuned for the continuous-taper barrel (0.024/mm from z=24) —
   // identical to cap_stations(): binds at 76.9% of bore depth
   [76.5,"axis"],[75.5,2.0],[74.5,4.0],[72.5,5.5],[70.5,6.35],[68.5,6.60],
   [66.5,5.880],
   [64.0,5.940],[56.0,6.132],[48.0,6.324],[40.0,6.516],[32.0,6.708],[24.0,6.90],
   [20.0,7.00],[16.0,7.10],[12.0,7.20],[8.0,7.30]],
  thread_stations_rev(0.0, 8.0, 2.0, "J4f")
  // thread runs straight to the mouth face (no smaller flat annulus),
  // then wraparound closes to [0.0,9.0]
);

// V2 cap, 70mm (2026-09-26): v14 elliptical dome; exterior measured from
// Brian's resin V2 cap. Same tapered bore as V3 so the V2 barrel posts too.
function cap_v2_stations() = concat(
  [[0.0,9.0],[2.0,9.0],[3.0,9.3],[5.0,9.3],
   [6.0,9.0],[10.0,9.0],[20.0,9.0],[30.0,8.95],[40.0,8.9],[50.0,8.85],
   [56.0,8.8],
   [58.0,8.65],[60.0,8.3],[62.0,7.7],[64.0,6.8],
   [66.0,5.5],[68.0,3.8],[69.0,2.0],[70.0,"axis"],
   [66.5,"axis"],[65.5,2.10],[64.5,4.10],[62.5,5.35],[60.5,6.05],
   [58.5,6.50],[56.5,5.730],
   // 2026-09-26: wedge taper 0.036/mm for the bezier-taper barrel —
   // binds at 77.4% of this shorter bore's depth. Exterior/J4/mouth unchanged.
   [54.0,5.820],[48.0,6.036],[42.0,6.252],[36.0,6.468],
   [30.0,6.684],[24.0,6.90],
   [20.0,7.00],[16.0,7.10],[12.0,7.20],[8.0,7.30]],
  thread_stations_rev(0.0, 8.0, 2.0, "J4f")
);

function coupon_stations() = concat(
  [[0.0,7.5],[20.0,7.5],[20.0,4.15],[18.8,4.15]],
  thread_stations_rev(13.0, 18.8, 1.0, "J1f"),
  [[13.0,4.35],[4.5,4.35],[2.0,4.35],[0.0,4.30]]
);

// Flared section grip (2026-09-29, per Brian's Leonardo photo): trumpet
// flare at the nib end. Baked from make_pen.py's _flare_grip_stations()
// (cubic Hermite through (0,5.95),(4,5.68),(7.5,5.50),(11,5.42),
// (14.5,5.82),(18,6.26),(22,6.60), sampled 0.5mm) — C1 smooth, no kinks.
// Shoulder r=6.6 @ z=22 unchanged; everything aft of it is identical to
// section_stations().
function section_flare_grip() = [
   [0.0000,5.9500],
   [0.5000,5.9158],
   [1.0000,5.8811],
   [1.5000,5.8461],
   [2.0000,5.8113],
   [2.5000,5.7769],
   [3.0000,5.7433],
   [3.5000,5.7109],
   [4.0000,5.6800],
   [4.5000,5.6503],
   [5.0000,5.6213],
   [5.5000,5.5934],
   [6.0000,5.5670],
   [6.5000,5.5424],
   [7.0000,5.5199],
   [7.5000,5.5000],
   [8.0000,5.4791],
   [8.5000,5.4559],
   [9.0000,5.4335],
   [9.5000,5.4155],
   [10.0000,5.4050],
   [10.5000,5.4054],
   [11.0000,5.4200],
   [11.5000,5.4516],
   [12.0000,5.4981],
   [12.5000,5.5557],
   [13.0000,5.6206],
   [13.5000,5.6888],
   [14.0000,5.7566],
   [14.5000,5.8200],
   [15.0000,5.8821],
   [15.5000,5.9472],
   [16.0000,6.0137],
   [16.5000,6.0800],
   [17.0000,6.1442],
   [17.5000,6.2048],
   [18.0000,6.2600],
   [18.5000,6.3098],
   [19.0000,6.3557],
   [19.5000,6.3986],
   [20.0000,6.4395],
   [20.5000,6.4792],
   [21.0000,6.5186],
   [21.5000,6.5585],
   [22.0000,6.6000],
];

function section_flare_stations() = concat(
  section_flare_grip(),
  thread_stations(22.0, 30.0, 1.5, "J2m"),
  [[30.0,4.15],[21.5,4.15],[18.8,4.15]],
  thread_stations_rev(13.0, 18.8, 1.0, "J1f"),
  [[13.0,4.35],[4.5,4.35],[2.0,4.35],[0.0,4.30]]
  // wraparound closes [0.0,4.30] -> [0.0,5.95]: the tip face
);

// Ballpoint section (2026-09-30, per Brian): fixed-tip section bored for a
// standard Parker G2 refill (98 x 5.8mm). Exterior IDENTICAL to
// Ballpoint section v3 (2026-09-30): pilot + funnel-jam + plug-trap.
// Reverse-engineered from the MakerWorld "Parker refill hexagon pen (Quink
// Flow Ballpoint)" reference STL (measured ~2.75mm nose hole). Interior:
//   * 2.75mm pilot hole (r=1.375) through the nose, z=0..2 — the refill's
//     2.5mm slim nose rides it as a bushing (no lateral play)
//   * straight steep cone z=2->4 to the jam ring (r=3.0 @ z=4.0), where the
//     refill's 6.0mm shoulder jams — the positive forward stop; writing
//     pressure can never push the tip back past it
//   * cosine ease z=4->5 (3.0->3.15) into the straight 6.3mm body bore
// Tip protrusion = 10.0mm. No J1 nib threads. A press-fit plug in the
// barrel bore behind the refill (see plug_stations) is the backward stop —
// the refill is captured; no spring, no rattle, no extra hardware.
// Baked from make_pen.py's _ballpoint_nose_stations() (identical stations);
// check_scad_agreement() in make_pen.py verifies 0.0 deviation.
// FDM caveat: the pilot prints ~0.5mm undersize -> ream to 2.75mm (7/64").
function section_ballpoint_stations() = concat(
  [[0.0,5.15],[2.0,5.35],[4.0,5.52],[6.0,5.66],
   [8.0,5.80],[10.0,5.94],[12.0,6.06],[14.0,6.18],
   [16.0,6.30],[18.0,6.40],[20.0,6.50],[22.0,6.60]],
  thread_stations(22.0, 30.0, 1.5, "J2m"),
  [[30.0,3.15],[4.8,3.1357],[4.6,3.0982],[4.4,3.0518],[4.0,3.0],
   [3.75,2.7969],[3.5,2.5938],[3.25,2.3906],[3.0,2.1875],[2.75,1.9844],
   [2.5,1.7812],[2.25,1.5781],[2.0,1.375],[0.3,1.375],[0.0,1.675]]
  // wraparound closes the tip face from z=0 r=1.675 out to z=0 r=5.15
);

// Press-fit trap plug (2026-09-30, v3): solid 10.08mm OD x 12mm cylinder
// (0.08mm diametral interference in the barrel's 10.0mm bore), 2deg lead
// chamfers both ends. Pushed into the barrel bore from the mouth with a
// dowel; its front face self-seats at the refill's back end (barrel z=66)
// when the section is screwed in — the positive backward stop capturing
// the refill. Baked from make_pen.py's plug_rows(); verified by
// check_scad_agreement(). Resin press-fit part.
function plug_stations() =
  [[0.0,"axis"],[0.0,5.005],[1.0,5.04],[11.0,5.04],[12.0,5.005],[12.0,"axis"],
   [0.0,"axis"]];

// Octagon cap (2026-09-26, per Brian): 8 flat sides, fairly flat top,
// chamfered mouth edge. Posts like the V3 (same 0.024/mm bore taper, same
// J4 female at the mouth). Interior (bore + J4) identical to V3;
// only the exterior is octagonal. r_flat matches the V3 body radius.
function cap_oct_stations() = concat(
  [[0.0,function(t) oct_r(8.5,t)],[1.0,function(t) oct_r(9.0,t)],
   [2.0,function(t) oct_r(9.0,t)],[10.0,function(t) oct_r(9.0,t)],
   [20.0,function(t) oct_r(9.0,t)],[30.0,function(t) oct_r(8.95,t)],
   [40.0,function(t) oct_r(8.9,t)],[50.0,function(t) oct_r(8.85,t)],
   [60.0,function(t) oct_r(8.82,t)],[70.0,function(t) oct_r(8.80,t)],
   [78.0,function(t) oct_r(8.78,t)],
   [79.0,function(t) oct_r(7.78,t)],
   [79.0,"axis"],
   [76.5,"axis"],[75.5,2.0],[74.5,4.0],[72.5,5.5],[70.5,6.35],[68.5,6.60],
   [66.5,5.880],
   [64.0,5.940],[56.0,6.132],[48.0,6.324],[40.0,6.516],[32.0,6.708],[24.0,6.90],
   [20.0,7.00],[16.0,7.10],[12.0,7.20],[8.0,7.30]],
  thread_stations_rev(0.0, 8.0, 2.0, "J4f"),
  [[0.0,function(t) oct_r(8.5,t)]]
);

// Fluted cap (2026-09-29, per Brian): 14 concave longitudinal flutes on the
// V3 body. Exterior only — the interior (bore + J4 female) is identical to
// cap_stations() so it screws on and posts exactly like the V3 (76.9%).
// Flute stations baked from make_pen.py's FLUTE_STATIONS (identical params);
// mouth, gold band, and dome top are untouched. Clipless.
function cap_fluted_stations() = concat(
  [[0.0,9.0],[2.0,9.0],[3.0,9.3],[5.0,9.3],[6.0,9.0]],
  [// baked from make_pen.py FLUTE_STATIONS + flute_r/flute_env (identical params)
   [8.0,function(t) flute_r(9.0,8.0,t)],
   [9.0,function(t) flute_r(9.0,9.0,t)],
   [10.0,function(t) flute_r(9.0,10.0,t)],
   [11.0,function(t) flute_r(9.0,11.0,t)],
   [12.0,function(t) flute_r(9.0,12.0,t)],
   [13.0,function(t) flute_r(9.0,13.0,t)],
   [14.0,function(t) flute_r(9.0,14.0,t)],
   [20.0,function(t) flute_r(9.0,20.0,t)],
   [30.0,function(t) flute_r(8.95,30.0,t)],
   [40.0,function(t) flute_r(8.9,40.0,t)],
   [50.0,function(t) flute_r(8.85,50.0,t)],
   [56.0,function(t) flute_r(8.8,56.0,t)],
   [62.0,function(t) flute_r(8.8,62.0,t)],
   [66.0,function(t) flute_r(8.7867,66.0,t)],
   [67.0,function(t) flute_r(8.7833,67.0,t)],
   [68.0,function(t) flute_r(8.78,68.0,t)],
   [69.0,function(t) flute_r(8.775,69.0,t)],
   [70.0,function(t) flute_r(8.77,70.0,t)],
   [71.0,function(t) flute_r(8.765,71.0,t)],
   [72.0,function(t) flute_r(8.76,72.0,t)]],
  [[74.0,8.75],
   // shallow "almost flat" crown (6mm) — identical to V3
   [76.0,8.5],[77.5,7.9],[78.5,6.9],[79.3,5.4],[79.8,3.2],[80.0,"axis"],
   // bore re-tuned for the continuous-taper barrel (0.024/mm from z=24) —
   // identical to cap_stations(): binds at 76.9% of bore depth
   [76.5,"axis"],[75.5,2.0],[74.5,4.0],[72.5,5.5],[70.5,6.35],[68.5,6.60],
   [66.5,5.880],
   [64.0,5.940],[56.0,6.132],[48.0,6.324],[40.0,6.516],[32.0,6.708],[24.0,6.90],
   [20.0,7.00],[16.0,7.10],[12.0,7.20],[8.0,7.30]],
  thread_stations_rev(0.0, 8.0, 2.0, "J4f")
  // thread runs straight to the mouth face (no smaller flat annulus),
  // then wraparound closes to [0.0,9.0]
);


// Square cap (2026-09-29, per Brian): squarish cross-section with highly
// chamfered 45-degree corners. Exterior only — the interior (bore + J4
// female) is identical to cap_stations() so it screws on and posts exactly
// like the V3 (76.9%). Round through the mouth band + J4 zone, C1 blend to
// square at z=8-14, square body to 78, 45-degree chamfer to a flat square
// top at 79 (octagon-cap treatment — no round dome on a square body).
// Station a-values baked from make_pen.py's _v3_body_r (identical params).
// Clipless.
function cap_square_stations() = concat(
  [[0.0,9.0],[2.0,9.0],[3.0,9.3],[5.0,9.3],[6.0,9.0]],
  [[8.0,function(t) sq_cap_r(9.0,8.0,t)],
   [9.0,function(t) sq_cap_r(9.0,9.0,t)],
   [10.0,function(t) sq_cap_r(9.0,10.0,t)],
   [11.0,function(t) sq_cap_r(9.0,11.0,t)],
   [12.0,function(t) sq_cap_r(9.0,12.0,t)],
   [13.0,function(t) sq_cap_r(9.0,13.0,t)],
   [14.0,function(t) sq_cap_r(9.0,14.0,t)],
   [20.0,function(t) sq_cap_r(9.0,20.0,t)],
   [30.0,function(t) sq_cap_r(8.95,30.0,t)],
   [40.0,function(t) sq_cap_r(8.9,40.0,t)],
   [50.0,function(t) sq_cap_r(8.85,50.0,t)],
   [56.0,function(t) sq_cap_r(8.8,56.0,t)],
   [62.0,function(t) sq_cap_r(8.8,62.0,t)],
   [68.0,function(t) sq_cap_r(8.78,68.0,t)],
   [74.0,function(t) sq_cap_r(8.75,74.0,t)],
   [76.0,function(t) sq_cap_r(8.75,76.0,t)],
   [78.0,function(t) sq_cap_r(8.75,78.0,t)]],
  [[79.0,function(t) sq_chamfer_r(7.75,2.5,t)],
   [79.0,"axis"],
   // bore re-tuned for the continuous-taper barrel (0.024/mm from z=24) —
   // identical to cap_stations(): binds at 76.9% of bore depth
   [76.5,"axis"],[75.5,2.0],[74.5,4.0],[72.5,5.5],[70.5,6.35],[68.5,6.60],
   [66.5,5.880],
   [64.0,5.940],[56.0,6.132],[48.0,6.324],[40.0,6.516],[32.0,6.708],[24.0,6.90],
   [20.0,7.00],[16.0,7.10],[12.0,7.20],[8.0,7.30]],
  thread_stations_rev(0.0, 8.0, 2.0, "J4f")
  // thread runs straight to the mouth face (no smaller flat annulus),
  // then wraparound closes to [0.0,9.0]
);

// ---------------- mesh builder: revolve stations -> watertight polyhedron ----------------
function cumsum(v, i=0, acc=0) =
  i >= len(v) ? [] : concat([acc], cumsum(v, i+1, acc+v[i]));

function seg_faces(s, s2, counts, offs) =
  let(na = counts[s], nb = counts[s2], oa = offs[s], ob = offs[s2])
  (na == 1 && nb == 1) ? [] :
  na == 1 ? [for(i=[0:nb-1]) [oa, ob+i, ob+((i+1)%nb)]] :
  nb == 1 ? [for(i=[0:na-1]) [ob, oa+((i+1)%na), oa+i]] :
  [for(i=[0:na-1]) each
    [[oa+i, ob+i, oa+((i+1)%na)], [oa+((i+1)%na), ob+i, ob+((i+1)%nb)]]];

module build_part(stations, nt) {
  thetas = [for(i=[0:nt-1]) i*360/nt];
  nr = len(stations);
  rings = [for(s=stations)
    s[1] == "axis" ? [[0,0,s[0]]] :
    [for(t=thetas)
      // 2026-09-26: station radius can be a number, a thread name (string),
      // or a function(t)->r for faceted profiles like the octagon cap
      let(r = is_string(s[1]) ? thread_fn(s[1], t, s[0]) :
              is_function(s[1]) ? s[1](t) : s[1])
      [r*cos(t), r*sin(t), s[0]]]];
  counts = [for(r=rings) len(r)];
  offs = cumsum(counts);
  points = [for(r=rings) for(p=r) p];
  // last ring wraps back to the first: the profile loop closes itself
  faces = [for(s=[0:nr-1]) each seg_faces(s, (s+1)%nr, counts, offs)];
  polyhedron(points=points, faces=faces, convexity=10);
}

module p_section(nt=DETAIL) build_part(section_stations(), nt);
module p_section_flare(nt=DETAIL) build_part(section_flare_stations(), nt);
module p_section_ballpoint(nt=DETAIL) build_part(section_ballpoint_stations(), nt);
module p_barrel(nt=DETAIL)  build_part(barrel_stations(), nt);
module p_cap(nt=DETAIL)     build_part(cap_stations(), nt);
module p_cap_v2(nt=DETAIL)  build_part(cap_v2_stations(), nt);
module p_cap_oct(nt=DETAIL) build_part(cap_oct_stations(), nt);
module p_cap_fluted(nt=DETAIL) build_part(cap_fluted_stations(), nt);
module p_cap_square(nt=DETAIL) build_part(cap_square_stations(), nt);
module p_cap_pisa(nt=DETAIL) build_part(cap_pisa_stations(), nt);
module p_coupon(nt=DETAIL)  build_part(coupon_stations(), nt);
module p_plug(nt=DETAIL)     build_part(plug_stations(), nt);

// ---------------- assembly ----------------
// Barrel frame: mouth z=0, back z=97.
// Section: tenon (local 22-30) slides into barrel mouth -> shift -22.
// Cap: flipped end-for-end; mouth (local 0) seats at barrel z=16 so the
//   cap's J4 female (local 0-8) fully overlaps the barrel's J4 male (8-16).
//   (2026-09-25: was translate 8, which parked the cap thread on the
//   barrel's smooth mouth instead of engaging the J4 male.)
module assembly(nt) {
  color("seagreen") p_barrel(nt);
  // +0.002: breaks the coplanar shoulder/mouth contact (CGAL-safe), invisible
  color("steelblue") translate([0,0,-22+0.002]) p_section(nt);
  color("slateblue") translate([0,0,16]) mirror([0,0,1]) mirror([0,1,0]) p_cap(nt);
}

// ---------------- dispatch ----------------
if (PART == "assembly") {
  asm_nt = min(DETAIL, 128); // previews stay interactive; raise for export
  if (SECTION_VIEW) {
    intersection() {
      assembly(asm_nt);
      translate([-200,0,-200]) cube([400,200,400]); // keep y>=0 half: cutaway
    }
  } else assembly(asm_nt);
}
else if (PART == "section") p_section();
else if (PART == "section_flare") p_section_flare();
else if (PART == "section_ballpoint") p_section_ballpoint();
else if (PART == "barrel")  p_barrel();
else if (PART == "cap")     p_cap();
else if (PART == "cap_v2")  p_cap_v2();
else if (PART == "cap_oct") p_cap_oct();
else if (PART == "cap_fluted") p_cap_fluted();
else if (PART == "cap_square") p_cap_square();
else if (PART == "cap_pisa") p_cap_pisa();
else if (PART == "coupon")  p_coupon();
else if (PART == "plug")    p_plug();
else echo("pen149.scad: unknown PART");
