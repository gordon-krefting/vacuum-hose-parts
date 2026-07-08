// Wall-mounted snap-in cradle for a vacuum hose running along the wall.
// Meant to be printed multiple times and spaced along the hose's run;
// screws to a wall/pegboard, hose snaps in from the top into a "C" cradle
// and is held by the springiness of the two arm tips.
//
// Axes: X = along the wall / along the hose run, Y = vertical, Z = out from the wall.

// ---- Edit these for your hose/screws ----
hose_od       = 40;   // measured hose OD (mm)
fit_clearance = 1;    // extra diametral clearance so the hose isn't overly tight
clip_wall     = 2.6;  // radial thickness of the cradle band (thin = flexes to snap)
clip_depth    = 20;   // width of this clip's band along the hose run (X)
gap_deg       = 90;   // total opening angle at the top where the hose snaps in

screw_margin  = 16;   // extra plate length above/below the cradle for screws
plate_thickness = 5;
plate_corner_r  = 4;

screw_hole_d    = 4.5; // clearance hole for a #8 wood screw
screw_head_d    = 9;   // counterbore diameter for the screw head
screw_head_depth = 2.6;
screw_edge_inset = 9;  // screw hole center distance from top/bottom plate edge

gusset_r = 5;          // thickness (radius) of the brace under the cradle

$fn_circle = 64;

// ---- Derived dimensions ----
clip_ir = (hose_od + fit_clearance) / 2;
clip_or = clip_ir + clip_wall;

cradle_offset_y = 5;   // shift the cradle up from center, clearing the bottom screw for a screwdriver

plate_w = clip_depth;   // plate is exactly as wide as the clip along the hose run (X)
plate_h = 2 * clip_or + 2 * screw_margin + cradle_offset_y;  // extra length added at the top, to keep the same clearance there after the shift

cx = plate_w / 2;
cy = clip_or + screw_margin + cradle_offset_y;   // cradle's vertical center (shifted up from plate center)

gap_start = 90 - gap_deg / 2;
gap_end   = 90 + gap_deg / 2;
arc_start = gap_end;
arc_end   = gap_start + 360;

screw_z_top    = plate_h - screw_edge_inset;
screw_z_bottom = screw_edge_inset;

module rounded_rect(w, h, r) {
    hull() {
        for (x = [r, w - r], y = [r, h - r])
            translate([x, y, 0])
                circle(r = r, $fn = 32);
    }
}

// Pie-slice / wedge from a1 to a2 degrees (measured counterclockwise from +X)
module pie(r, a1, a2) {
    steps = max(6, ceil((a2 - a1) / 360 * $fn_circle));
    points = concat([[0, 0]],
        [for (i = [0:steps])
            let (a = a1 + (a2 - a1) * i / steps)
            [r * cos(a), r * sin(a)]]);
    polygon(points);
}

// Brace filling the gap between the ring's lower outer surface and the wall
// plate (native +x embeds into the plate; see cradle() below). Drawn before
// the bore is cut, so it can be sized generously with no risk of narrowing
// the hose clearance. The root anchor is centered at the plate's mid-thickness
// with a capped radius so it can never poke through the front or back face.
gusset_root_r = min(gusset_r, plate_thickness / 2 - 0.3);

module gusset_2d() {
    hull() {
        translate([0, -clip_or]) circle(r = gusset_r, $fn = 24);
        translate([clip_ir + plate_thickness / 2, -clip_or * 0.4]) circle(r = gusset_root_r, $fn = 24);
    }
}

module cradle_2d() {
    difference() {
        union() {
            intersection() {
                circle(r = clip_or, $fn = $fn_circle);
                pie(clip_or + 2, arc_start, arc_end);
            }
            gusset_2d();
        }
        circle(r = clip_ir, $fn = $fn_circle);
    }
}

module screw_hole() {
    cylinder(h = plate_thickness + 2, r = screw_hole_d / 2, $fn = 32);
}

module screw_counterbore() {
    translate([0, 0, plate_thickness - screw_head_depth])
        cylinder(h = screw_head_depth + 1, r = screw_head_d / 2, $fn = 32);
}

module wall_plate() {
    difference() {
        linear_extrude(height = plate_thickness)
            rounded_rect(plate_w, plate_h, plate_corner_r);

        translate([cx, screw_z_top, -1]) screw_hole();
        translate([cx, screw_z_bottom, -1]) screw_hole();
        translate([cx, screw_z_top, 0]) screw_counterbore();
        translate([cx, screw_z_bottom, 0]) screw_counterbore();
    }
}

// Ring profile is drawn in native X/Y with the gap at +Y (up), then rotated
// so the extrusion runs along world X (along the wall) instead of world Z,
// while its local Y axis (gap direction) stays mapped to world Y (vertical).
module cradle() {
    translate([(plate_w - clip_depth) / 2, cy, plate_thickness + clip_ir])
        rotate([0, 90, 0])
            linear_extrude(height = clip_depth)
                cradle_2d();
}

union() {
    wall_plate();
    cradle();
}
