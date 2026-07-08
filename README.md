# vacuum-hose-parts

I've got a lot of vacuums, hoses and tools in my shop. I 3D print a lot of adaptors for them. Gotta admit, Claude Code is faster at this than I am. I still need to do the measuring though, proving that humans are not entirely useless!

## What's here

Parametric OpenSCAD sources for shop-vac hose adaptors, built around a reproduction of a Cen-Tec Quick Click hose collar.

- `scad/hose_adaptor_ring.scad` — reusable Quick Click collar module (taper, detent pin holes, hose-barb cap/lip)
- `scad/bandsaw_hose_adaptor.scad` — 90-degree elbow adaptor from the collar down to a 63.5mm bandsaw dust port sleeve; splits into two print-flat halves with alignment dowels, plus a short test-fit ring
- `scad/wall_hose_clip.scad` — wall-mounted snap-in cradle for running a hose along a wall

## Building

Requires [OpenSCAD](https://openscad.org/) (2021.01+; the Manifold backend is recommended for speed and more reliable manifold checks on `bandsaw_hose_adaptor.scad`'s bend geometry).

```bash
openscad --backend Manifold -o hose_adaptor_ring.stl scad/hose_adaptor_ring.scad
openscad --backend Manifold -D 'output="half_a"' -o half_a.stl scad/bandsaw_hose_adaptor.scad
openscad --backend Manifold -D 'output="half_b"' -o half_b.stl scad/bandsaw_hose_adaptor.scad
openscad --backend Manifold -D 'output="dowels"' -o dowels.stl scad/bandsaw_hose_adaptor.scad
openscad --backend Manifold -D 'output="port_fit_test"' -o port_fit_test.stl scad/bandsaw_hose_adaptor.scad
openscad --backend Manifold -o wall_hose_clip.stl scad/wall_hose_clip.scad
```

STL exports aren't tracked in this repo (see `.gitignore`) — they're fully reproducible from the sources above.
