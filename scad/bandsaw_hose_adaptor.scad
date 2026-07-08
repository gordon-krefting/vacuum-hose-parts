// Bandsaw dust port adaptor: the Quick Click collar (reused as-is, with the
// hose-barb cap/lip) sits on a sleeve that fits over the bandsaw's dust
// port. A short straight "neck" tapers the diameter down from the sleeve's
// size to the collar's size, then a 90-degree bend (constant diameter)
// turns the collar to point horizontally.
// Axes: sleeve is vertical (Z) sitting on the print bed at Z=0; the bend
// turns over so the collar ends up horizontal, pointing along +X.
//
// The diameter transition is done in the straight neck rather than during
// the bend itself: the bend's tube diameter has to stay well under the
// bend radius to avoid self-intersecting, and the neck's larger sleeve-end
// diameter would otherwise force a much bigger (and much bigger-looking)
// bend than the collar-sized tube actually needs.
//
// The whole part is symmetric about the Y=0 plane (the bend's own plane),
// so it splits cleanly into two print-flat halves along that plane. Export
// each half separately for printing; each has a row of recessed sockets
// along the seam that take a short loose dowel to register the halves
// before gluing. See `output` below for how to select what gets exported
// (the full assembly, either half, the loose dowels, or a small test ring
// to check the port fit before committing to a full print).

use <hose_adaptor_ring.scad>

// ---- Edit these ----
port_od        = 63.5;  // bandsaw dust port outer diameter (mm) -- measured
port_clearance = 0.4;   // diametral clearance for a snug push fit (mm) -- confirmed via test-fit print
sleeve_depth   = 30;    // how far the sleeve extends down over the port (mm) -- measured
sleeve_wall    = 2.5;   // sleeve wall thickness (mm) -- confirmed

neck_height = 15;  // height of the straight taper from sleeve size to collar size (mm) -- confirmed

bend_radius = 30;  // centerline radius of the 90-degree bend (mm) -- confirmed.
                    // The bend is a mathematically exact constant-diameter torus segment
                    // (rotate_extrude), not an approximated sweep, so the true minimum is just
                    // collar_od/2 (25.2mm) -- below that the tube's material would pinch to
                    // nothing at the innermost point of the curve. 30mm keeps a ~5mm safety
                    // margin above that; checked clean down to 25.3mm (0.1mm above the limit),
                    // but that leaves no real margin for a physical print.

// Must match the collar dimensions passed to hose_adaptor_ring() below.
collar_od          = 50.4;
collar_wall_bottom = 2.7;
collar_id_bottom   = collar_od - 2 * collar_wall_bottom;

sleeve_id = port_od + port_clearance;
sleeve_od = sleeve_id + 2 * sleeve_wall;

// Which part variant to generate -- set with -D when exporting, e.g.
// openscad -D 'output="half_a"' -o half_a.stl bandsaw_hose_adaptor.scad
//   "full"           unsplit assembly, for preview/reference (default)
//   "half_a"         printable half with sockets (keeps the y>=0 material)
//   "half_b"         printable half with sockets (keeps the y<=0 material)
//   "dowels"         the loose alignment dowels, one print for all sockets
//   "port_fit_test"  short test ring of the sleeve, to check the port fit
//                    before committing to printing the whole thing
output = "full";
test_ring_height = 10;  // mm -- height of the port_fit_test ring

// Alignment sockets at the seam, to register the two halves for gluing.
// Both halves get a *recessed* socket (into their own material) rather
// than a protruding pin -- a printed pin sticking past the flat face would
// need support once that face is printed flat-down (the orientation the
// shell itself needs to avoid support). Instead, a short loose dowel
// (printed separately, see alignment_dowels.scad) drops into both sockets
// at glue-up.
pin_d          = 1.2;  // dowel diameter (mm) -- the socket is cut in from the mid-wall point,
                        // so only wall_thickness/2 (~1.25mm) of material surrounds it on each
                        // side; at 2mm dowel diameter that left just ~0.15mm of plastic around
                        // the hole (thinner than a nozzle line), so this is sized down to leave
                        // a real margin (~0.55mm) instead
socket_depth   = 3;    // how deep each socket goes into its own half (mm)
pin_clearance  = 0.2;  // extra diametral clearance on the sockets (mm)
dowel_len      = 2 * socket_depth - 0.5;  // slightly less than the combined socket depth,
                                           // so the two flat faces still meet flush

$fn = 128;

module sleeve(height = sleeve_depth) {
    difference() {
        cylinder(h = height, d = sleeve_od);

        translate([0, 0, -0.1])
            cylinder(h = height + 0.2, d = sleeve_id);
    }
}

// Straight taper from the sleeve's diameter down to the collar's diameter.
function od_at_neck(u) = sleeve_od + (collar_od - sleeve_od) * u;
function id_at_neck(u) = sleeve_id + (collar_id_bottom - sleeve_id) * u;

module neck() {
    difference() {
        cylinder(h = neck_height, d1 = sleeve_od, d2 = collar_od);

        translate([0, 0, -0.1])
            cylinder(h = neck_height + 0.2, d1 = sleeve_id, d2 = collar_id_bottom);
    }
}

// Constant-diameter 90-degree bend, built with rotate_extrude (an exact
// revolve, not an approximated sweep) so it stays clean at much tighter
// radii than a varying-diameter sweep could. rotate_extrude only revolves
// around Z, giving a start tangent of +Y and an end tangent of -X; the
// mirror+rotate below re-orients that to start at +Z (matching the neck
// above it) and end at +X (matching the collar's through-axis), while
// keeping everything in the Y=0 plane so the split-in-half symmetry holds.
module bend() {
    mirror([1, 0, 0])
        rotate([90, 0, 0])
            rotate_extrude(angle = 90)
                translate([bend_radius, 0])
                    difference() {
                        circle(d = collar_od);
                        circle(d = collar_id_bottom);
                    }
}

neck_top_z = sleeve_depth + neck_height;

// Where the bend's far end lands, in world coordinates -- used to place
// the collar flush onto it. (Derived from the same mirror+rotate chain as
// bend() above: the bend's start lands at [-bend_radius,0,0] and its end
// at [0,0,bend_radius], so translating the whole bend by
// [bend_radius,0,neck_top_z] puts the start at the neck's top.)
bend_end_pos = [bend_radius, 0, neck_top_z + bend_radius];
bend_end_rot = [0, 90, 0];
collar_spin  = 90;  // rotation of the collar about its own through-axis (degrees) --
                     // moves the pin holes off the Y=0 split plane (see half_a/half_b)
                     // rather than straddling it

module full_body() {
    union() {
        sleeve();

        translate([0, 0, sleeve_depth])
            neck();

        translate([bend_radius, 0, neck_top_z])
            bend();

        translate(bend_end_pos)
            rotate(bend_end_rot)
                rotate([0, 0, collar_spin])
                    hose_adaptor_ring(od = collar_od, wall_bottom = collar_wall_bottom);
    }
}

// Points on the seam (Y=0) plane, at the mid-wall radius, where the two
// halves get an alignment socket. "side" picks which of the wall's two
// strips (the tube cut by a plane through its axis leaves two strips of
// material, one per side) -- covers the straight neck and three stations
// along the bend's curve. The collar itself (a shared module) isn't given
// sockets, so registration there relies on the last bend station being close by.
function neck_wall_point(u, side) =
    let (mr = (od_at_neck(u) + id_at_neck(u)) / 4)
    [side * mr, 0, sleeve_depth + u * neck_height];

// Mirrors the position half of bend()'s transform chain (mirror + rotate +
// translate) for a point on the swept circle at sweep-angle phi and local
// circle-angle 0/180 (side = +1 / -1), radius mid_wall_r from the bend's
// own tube axis.
function bend_wall_point(phi, side) =
    let (mr = (collar_od + collar_id_bottom) / 4, u = bend_radius + side * mr)
    [bend_radius - u * cos(phi), 0, neck_top_z + u * sin(phi)];

sleeve_mid_r = (sleeve_od + sleeve_id) / 4;
sleeve_pin_z = sleeve_depth * 0.5;

bend_pin_phis = [20, 45, 70];

alignment_points = concat(
    [[sleeve_mid_r, 0, sleeve_pin_z], [-sleeve_mid_r, 0, sleeve_pin_z]],
    [[neck_wall_point(0.5, 1)[0], 0, neck_wall_point(0.5, 1)[2]]],
    [[neck_wall_point(0.5, -1)[0], 0, neck_wall_point(0.5, -1)[2]]],
    [for (phi = bend_pin_phis) bend_wall_point(phi, 1)],
    [for (phi = bend_pin_phis) bend_wall_point(phi, -1)]
);

// Sockets recessed into each half's own material -- half A's go into +Y
// (since it keeps the y>=0 material), half B's into -Y. Neither crosses
// the seam, so neither needs support when printed with the seam face down.
module alignment_sockets(into_positive_y) {
    for (pt = alignment_points)
        translate(pt)
            rotate([into_positive_y ? -90 : 90, 0, 0])
                cylinder(h = socket_depth, d = pin_d + pin_clearance);
}

module half_a() {
    difference() {
        intersection() {
            full_body();
            translate([-1000, 0, -1000]) cube([2000, 2000, 2000]);
        }
        alignment_sockets(true);
    }
}

module half_b() {
    difference() {
        intersection() {
            full_body();
            translate([-1000, -2000, -1000]) cube([2000, 2000, 2000]);
        }
        alignment_sockets(false);
    }
}

// Loose dowels for the alignment sockets -- one print gives enough for
// every socket pair. Standing upright in a row; trivial to print without
// support at this size.
module dowels() {
    spacing = pin_d * 3;

    for (i = [0 : len(alignment_points) - 1])
        translate([i * spacing, 0, 0])
            cylinder(h = dowel_len, d = pin_d);
}

if (output == "half_a") {
    half_a();
} else if (output == "half_b") {
    half_b();
} else if (output == "dowels") {
    dowels();
} else if (output == "port_fit_test") {
    sleeve(height = test_ring_height);
} else {
    full_body();
}
