# Mod Pen — a modular 3D-printable fountain pen

**Mod Pen** is an open-source fountain pen you print yourself: one
barrel, a family of interchangeable caps, and two grip sections. Every
cap screws onto the same barrel and posts on the matching wedge at the
back, so you can mix and match to taste. It is designed in the spirit
of classic oversized piston-era pens, built from scratch for resin and
FDM printing, and every thread joint was validated against a simulated
screw-on path before it was ever printed.

📄 The full illustrated story is in
[Docs/ModPen-Design-History.pdf](Docs/ModPen-Design-History.pdf).
I have some photos in my [Instagram](https://www.instagram.com/bjjworkshop/).

## What's included

| Folder | Contents |
|---|---|
| `Barrel/` | The single barrel every cap and section fits |
| `Caps/` | Six cap designs, all interchangeable |
| `Sections/` | Two fountain-pen grip sections (Jinhao #6 nib unit) |
| `Source/` | `ModPen.scad` — the parametric OpenSCAD master that generates every part |
| `Docs/` | `ModPen-Design-History.pdf` — the illustrated design history of the project |

## The parts

**Barrel** — `ModPen-Barrel.stl`. 93 mm, smooth bezier taper, with a
threaded post band at the back so any cap screws on to post, exactly
as it does at the front.

**Caps** — all six thread onto the barrel's front and post onto the
back band:

| Nickname | File | Style |
|---|---|---|
| Campanile | `ModPen-Cap-Campanile.stl` | Smooth round cap, shallow crown (the tall flagship) |
| Cupola | `ModPen-Cap-Cupola.stl` | Smooth round cap, fuller domed crown |
| Otto | `ModPen-Cap-Otto.stl` | Eight flat facets, chamfered mouth |
| Colonna | `ModPen-Cap-Colonna.stl` | Fluted, like a classical column |
| Piazza | `ModPen-Cap-Piazza.stl` | Beveled-square profile |
| Pisa | `ModPen-Cap-Pisa.stl` | Tower-inspired: fine vertical ribs and five raised floor beads (stands up straight, unlike the original) |

**Sections** — `ModPen-Section-Standard.stl` (classic straight grip)
and `ModPen-Section-Flared.stl` (flares out at the nib end, prints
support-free). Both take a Jinhao #6 screw-in nib unit and use the
same barrel joint.

## Making one

- **Recommended:** resin (SLA) for the finished pen — the STLs carry
  the final clearances (0.45–0.50 mm radial on the thread joints).
- **FDM works** for prototyping: 0.12 mm layers, 100% infill, slow
  outer walls. In the OpenSCAD master, set `MODE="prototype"` to add
  FDM compensation.
- You will need one Jinhao #6 nib unit per pen. Sections, barrel, and
  caps are all printed; no other hardware.
- Every cap is interchangeable: pick a cap, pick a section, one barrel,
  and you have a pen.

## Customizing

Open `Source/ModPen.scad` in OpenSCAD, set `PART` to the piece you
want (`barrel`, `cap`, `cap_v2`, `cap_oct`, `cap_fluted`, `cap_square`,
`cap_pisa`, `section`, `section_flare`), set `MODE` and `DETAIL`, then
export your own STL. `PART="assembly"` previews the whole pen, and
`PART="coupon"` prints a small thread-fit test piece — worth doing
first on a new printer or resin.

## License

Mod Pen is © 2026 Brian Johnson, released under the **Creative
Commons Attribution 4.0 International License (CC BY 4.0)** — see
[LICENSE](LICENSE). You may print it, remix it, and sell what you
make, commercially or otherwise. Just give credit:

> Mod Pen by Brian Johnson — licensed under CC BY 4.0
> (https://creativecommons.org/licenses/by/4.0/)

Designed from scratch in September–October 2026 — no derived
third-party CAD, so there is no other license baggage attached.
