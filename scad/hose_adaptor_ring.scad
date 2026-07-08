// Hollow cylindrical collar from a hose adaptor (Cen-Tec Quick Click style):
// outer wall is a plain cylinder, the taper lives on the inside wall, plus
// two detent pin holes and a bottom cap with a lipped center hole.
// Axes: Z = height, bottom face sits on the print bed at Z=0.
//
// Reusable module -- import into another project with:
//   use <hose_adaptor_ring.scad>
//   hose_adaptor_ring();
// All dimensions are optional overrides; defaults are the measured values.
module hose_adaptor_ring(
    height      = 31.8,  // overall height (mm)
    od          = 50.4,  // outer diameter, constant top to bottom (mm)
    wall_bottom = 2.7,   // wall thickness at the bottom (mm)
    wall_top    = 2.3,   // wall thickness at the top (mm)

    // Detent pin holes: a trapezoid capped with an arc (narrow at the
    // bottom, arced top), not round. The two holes sit on the same
    // diameter (180 degrees apart), cut with a single shape all the way
    // through.
    hole_bottom_w      = 9.7,   // width at the bottom (narrow) edge (mm)
    hole_top_w         = 11.1,  // width where the straight sides meet the arc (mm)
    hole_height        = 10.7,  // total height, bottom edge to the top of the arc (mm)
    hole_arc_sag       = 2,     // how far the arc bulges above the straight top corners (mm)
    hole_edge_from_top = 10,    // gap from the ring's top edge to the top of the hole (mm)

    // Outer chamfer around each hole opening, for finger access: the
    // opening widens by a constant amount on every side at the outer
    // surface, tapering linearly back down to the hole shape.
    chamfer_extra = 2,   // extra width on each side at the outer surface (mm)
    chamfer_depth = 1.5, // how far the chamfer cuts in from the outer surface (mm)

    // Bottom cap: closes off the bottom of the bore except for a central
    // hole, flush with the ring's bottom edge.
    cap_thickness = 3,   // thickness of the cap (mm)

    // Lip standing up around the cap's hole, into the bore. Its outer
    // diameter is sized to the hose barb (32mm) that pushes onto it; the
    // hole through the cap/lip is derived by subtracting the lip's wall
    // thickness on each side.
    lip_height  = 3,      // how tall the lip stands above the cap (mm)
    lip_wall    = 1.75,   // radial wall thickness of the lip (mm) -- measured
    lip_outer_d = 32,      // outer diameter of the lip -- matches the hose barb OD (mm)

    include_cap = true,  // set false to leave the bore fully open (no cap/lip)

    fn = 128
) {
    id_bottom = od - 2 * wall_bottom;
    id_top    = od - 2 * wall_top;

    cap_hole_d = lip_outer_d - 2 * lip_wall;  // diameter of the hole through the cap/lip

    hole_chord_h  = hole_height - hole_arc_sag;   // height to the straight top corners
    hole_top_z    = height - hole_edge_from_top;  // world Z of the arc's peak
    hole_bottom_z = hole_top_z - hole_height;     // world Z of the hole's bottom edge

    // 2D profile: straight bottom edge, straight sides, arc across the top.
    // Drawn with x = width (centered on 0), y = height (0 at the bottom edge).
    module hole_profile2d() {
        r = (hole_arc_sag * hole_arc_sag + (hole_top_w / 2) * (hole_top_w / 2)) / (2 * hole_arc_sag);
        center_v = hole_chord_h - (r - hole_arc_sag);
        half_angle = asin((hole_top_w / 2) / r);

        arc_steps = 16;
        arc_pts = [for (i = [0 : arc_steps])
            let (a = 90 - half_angle + (2 * half_angle) * i / arc_steps)
            [r * cos(a), center_v + r * sin(a)]
        ];

        polygon(concat(
            [[-hole_bottom_w / 2, 0], [hole_bottom_w / 2, 0]],
            arc_pts
        ));
    }

    // Chamfer for one opening: loft from the hole profile up to the profile
    // offset outward by chamfer_extra on every side, over chamfer_depth.
    module chamfer_lobe() {
        thin = 0.01;
        hull() {
            linear_extrude(height = thin)
                hole_profile2d();
            translate([0, 0, chamfer_depth])
                linear_extrude(height = thin)
                    offset(r = chamfer_extra)
                        hole_profile2d();
        }
    }

    // Both openings cut with one shape swept through the full diameter
    // (local Z of the extrusion becomes the radial/world-X axis after
    // these rotates).
    module pin_holes() {
        hole_len = od + 4;  // long enough to clear both walls with margin

        translate([0, 0, hole_bottom_z])
            rotate([0, 90, 0])
                rotate([0, 0, 90]) {
                    translate([0, 0, -hole_len / 2])
                        linear_extrude(height = hole_len)
                            hole_profile2d();

                    // Chamfer at the +X opening.
                    translate([0, 0, od / 2 - chamfer_depth])
                        chamfer_lobe();

                    // Chamfer at the -X opening (mirrored).
                    mirror([0, 0, 1])
                        translate([0, 0, od / 2 - chamfer_depth])
                            chamfer_lobe();
                }
    }

    // Fills the bore flush with the bottom edge, out to the inner wall
    // (using id_bottom -- the taper's effect over just the cap's thickness
    // is negligible). Sized very slightly past id_bottom so it genuinely
    // overlaps the surrounding wall material rather than just touching it
    // -- when this ring is unioned onto separately-generated geometry (e.g.
    // a rotate_extrude bend) with a bore at exactly the same radius, an
    // exact (non-overlapping) coincidence between the two independently
    // tessellated surfaces can confuse the boolean engine into producing a
    // non-manifold result even though they're analytically flush.
    module cap() {
        difference() {
            cylinder(h = cap_thickness, d = id_bottom + 0.3);

            translate([0, 0, -0.1])
                cylinder(h = cap_thickness + 0.2, d = cap_hole_d);
        }
    }

    // Upstanding ring around the cap's hole, continuing the same bore
    // diameter up into the print.
    module cap_lip() {
        translate([0, 0, cap_thickness])
            difference() {
                cylinder(h = lip_height, d = lip_outer_d);

                translate([0, 0, -0.1])
                    cylinder(h = lip_height + 0.2, d = cap_hole_d);
            }
    }

    $fn = fn;

    union() {
        difference() {
            cylinder(h = height, d = od);

            // Extended slightly past both ends so the cut faces don't
            // coincide exactly with the outer cylinder's faces (avoids
            // z-fighting in the preview / non-manifold edges).
            translate([0, 0, -0.1])
                cylinder(h = height + 0.2, d1 = id_bottom, d2 = id_top);

            pin_holes();
        }

        if (include_cap) {
            cap();
            cap_lip();
        }
    }
}

// Preview when this file is opened directly; not run when imported with use<>.
hose_adaptor_ring();
