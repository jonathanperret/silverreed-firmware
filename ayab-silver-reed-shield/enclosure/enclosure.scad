// Enclosure for Arduino UNO (R3 / R4 / clones) + AYAB Silver Reed shield v0.4
//
// Coordinates: x/y are Arduino board coordinates in mm (origin at the board
// corner next to the DC jack, x pointing away from the USB edge), z = 0 is the
// underside of the enclosure.
//
// Export:  openscad -D 'part="tray"' -o tray.stl enclosure.scad
//          openscad -D 'part="lid"'  -o lid.stl  enclosure.scad   (already flipped for printing)
// The lid snaps on (fastening = "snap"): no hardware needed. Pull it off using
// the fingernail notches on the long sides.
// With fastening = "screws": 4x M3x10, self-tapping into the corner bosses.

part = "assembly"; // [assembly, tray, lid, print]

/* [Shell] */
wall = 2.4;
floor_t = 2.0;
lid_t = 2.0;
// PCB edge to inner wall on the three non-USB sides
side_clr = 0.8;
// PCB edge to inner wall on the USB side. Must exceed the DC jack overhang of
// the worst clone (original: 1.9, clones seen: up to ~4) and of the shield jack (4.05).
usb_side_gap = 4.8;
// distance of the screw axis from the inner corner; also sets the outer corner radius
screw_inset = 0.6;

/* [Stack heights] */
standoff_h = 3.0;   // room for solder joints under the Arduino
pcb_t = 1.6;
board_gap = 11.2;   // Arduino top to shield underside (8.5 socket + 2.54 header + slack)
shield_top_h = 19.65; // tallest part on the shield (DIN socket)
top_clr = 0.75;

/* [Openings] */
usb_y = 38.1;       // centre of USB-B (and of USB-C on clones / R4)
usb_w = 13.0;       // USB-B body is 12.0 wide; a USB-C overmold is <= 12.35
usb_top = 11.4;     // above the Arduino PCB top (USB-B is 10.9 tall)
usb_bottom = -2.1;  // below the Arduino PCB top: a USB-C overmold hangs below the board
jack_y = 20.07;     // shield DC jack axis
jack_z = 6.4;       // above the shield PCB top
jack_d = 12.0;      // lets the plug handle reach the jack, which sits behind the wall
din_y = 17.21;      // DIN socket axis
din_z = 10.03;      // above the shield PCB top
din_d = 18.0;

/* [Fasteners] */
fastening = "snap"; // [snap, screws]
snap_x = [26, 54];   // arm centres along each long wall
snap_w = 8;          // arm width
snap_t = 1.5;        // arm thickness
snap_len = 14;       // arm length below the lid
snap_z = 12.5;       // hook apex below the lid
snap_p = 0.9;        // hook protrusion from the arm (engagement = snap_p - fit)
screw_pilot_d = 2.5; // M3 thread-forming
screw_clear_d = 3.4;
screw_depth = 14;
boss_r = 2.4;
peg_d = 2.8;         // goes into the 3.2 mm Arduino mounting holes
peg_h = 1.4;
standoff_d = 5.0;

/* [Lid logo] */
logo_w = 60;           // width of the AYAB logo on the lid; 0 = no logo
logo_depth = 0.5;      // letters and tagline
logo_fill_depth = 0.2; // yarn fills of the letters, one layer deep

/* [Fit] */
fit = 0.25;          // clearance between tray and lid features
end_lip_fit = 0.15;  // lid end lips to the short walls: sets the lid's play along x
post_slack = 0.3;    // lid posts stop this far above the shield
label_depth = 0.6;

$fn = 48;
eps = 0.01;

// ---------------------------------------------------------------- derived
ard_w = 68.58;
ard_h = 53.34;
ix0 = -usb_side_gap;
ix1 = ard_w + side_clr;
iy0 = -side_clr;
iy1 = ard_h + side_clr;
corner_r = wall + screw_inset;

z_ard_bot = floor_t + standoff_h;
z_ard = z_ard_bot + pcb_t;            // Arduino PCB top
z_sh_bot = z_ard + board_gap;
z_sh = z_sh_bot + pcb_t;              // shield PCB top
z_top = z_sh + shield_top_h + top_clr; // top of tray walls = lid underside

ard_holes = [[13.97, 2.54], [15.24, 50.8], [66.04, 7.62], [66.04, 35.56]];
shield_holes = [[13.97, 2.54], [15.24, 50.8], [66.04, 35.56]];
screws = [for (x = [ix0 + screw_inset, ix1 - screw_inset],
               y = [iy0 + screw_inset, iy1 - screw_inset]) [x, y]];

echo(outer_size = [ix1 - ix0 + 2 * wall, iy1 - iy0 + 2 * wall, z_top + lid_t]);

// ---------------------------------------------------------------- helpers
module outline() {
    hull() for (p = screws) translate(p) circle(r = corner_r);
}

module cavity() {
    translate([ix0, iy0]) square([ix1 - ix0, iy1 - iy0]);
}

// DC barrel jack polarity symbol, centre positive: (-)--C*--(+)
module ring(r, s) {
    difference() { circle(r = r + s / 2); circle(r = r - s / 2); }
}

module arc(r, s, a0, a1, n = 40) {
    pts_o = [for (i = [0:n]) let (a = a0 + (a1 - a0) * i / n) (r + s / 2) * [cos(a), sin(a)]];
    pts_i = [for (i = [n:-1:0]) let (a = a0 + (a1 - a0) * i / n) (r - s / 2) * [cos(a), sin(a)]];
    polygon(concat(pts_o, pts_i));
}

module polarity_symbol(s = 0.75) {
    cx = 9.2; // centre of the +/- circles
    cr = 2.5;
    // (-) on the left, wired to the sleeve (the C)
    translate([-cx, 0]) { ring(cr, s); square([cr * 1.1, s], center = true); }
    translate([-(cx - cr + 2.4) / 2 - 0.05, 0]) square([cx - cr - 2.4 + 0.1, s], center = true);
    arc(2.4, s, 55, 305);
    // centre pin, wired to (+) on the right
    circle(r = 1.05);
    translate([(cx - cr) / 2, 0]) square([cx - cr, s], center = true);
    translate([cx, 0]) {
        ring(cr, s);
        square([cr * 1.1, s], center = true);
        square([s, cr * 1.1], center = true);
    }
}

// 2D artwork placed on the outside of the USB-side wall, readable from outside
module on_usb_wall(y, z) {
    translate([ix0 - wall, y, z]) rotate([90, 0, -90])
        linear_extrude(2 * label_depth, center = true) children();
}

// Snap arm profile against a wall whose inner face is at u = 0 (u pointing into
// the box), v = 0 at the lid underside. Symmetric 45 degree hook: clicks in and
// pulls out by hand, and prints without support with the lid upside down.
module snap_arm() {
    rotate([90, 0, 90]) linear_extrude(snap_w, center = true)
        polygon([[fit, eps], [fit + snap_t, eps], [fit + snap_t, -snap_len], [fit, -snap_len],
                 [fit, -snap_z - snap_p], [fit - snap_p, -snap_z], [fit, -snap_z + snap_p]]);
}

module snap_groove() {
    g = snap_p - fit + 0.25;
    rotate([90, 0, 90]) linear_extrude(snap_w + 1.5, center = true)
        polygon([[eps, -snap_z - g - 0.3], [-g, -snap_z], [eps, -snap_z + g + 0.3]]);
}

// Lip under the lid against a short wall whose inner face is at u = 0, running
// from y0 to y1; chamfered lead-in. Stops the lid sliding along the long axis.
module end_lip(y0, y1) {
    f = end_lip_fit;
    translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0)
        polygon([[f, eps], [f + 1.5, eps], [f + 1.5, -3], [f + 0.7, -3], [f, -2.3]]);
}

// places children on both long walls, at each snap position
module at_snaps() {
    for (x = snap_x) {
        translate([x, iy0, z_top]) children();
        translate([x, iy1, z_top]) mirror([0, 1, 0]) children();
    }
}

// ---------------------------------------------------------------- tray
module tray() {
    difference() {
        union() {
            difference() {
                linear_extrude(z_top) outline();
                translate([0, 0, floor_t]) linear_extrude(z_top) cavity();
            }
            // standoffs with locating pegs under the Arduino
            for (p = ard_holes) translate(p) {
                cylinder(d1 = standoff_d + 2, d2 = standoff_d, h = z_ard_bot);
                cylinder(d = peg_d, h = z_ard_bot + peg_h);
                translate([0, 0, z_ard_bot + peg_h]) cylinder(d1 = peg_d, d2 = peg_d - 1, h = 0.6);
            }
            // screw bosses in the corners
            if (fastening == "screws") intersection() {
                linear_extrude(z_top) cavity();
                for (p = screws) translate(p) cylinder(r = boss_r, h = z_top);
            }
        }

        // USB slot, open to the top so the stack drops straight in
        translate([ix0 - wall - 1, usb_y - usb_w / 2, z_ard + usb_bottom])
            cube([wall + 2, usb_w, z_top]);

        // shield DC jack
        translate([ix0 - wall - 1, jack_y, z_sh + jack_z]) rotate([0, 90, 0])
            cylinder(d = jack_d, h = wall + 2);

        // DIN socket
        translate([ix1 - 1, din_y, z_sh + din_z]) rotate([0, 90, 0])
            cylinder(d = din_d, h = wall + 2);

        if (fastening == "snap") {
            at_snaps() snap_groove();
            // fingernail notches under the lid edge
            for (y = [iy0 - wall - eps, iy1 + wall - 1.2 + eps])
                translate([ard_w / 2 - 7, y, z_top - 1.5]) cube([14, 1.2, 1.5 + eps]);
        }

        // screw pilot holes
        if (fastening == "screws") for (p = screws) translate([p.x, p.y, z_top - screw_depth])
            cylinder(d = screw_pilot_d, h = screw_depth + 1);

        // label under the shield jack: rating + polarity
        label_y = (iy0 - wall + usb_y - usb_w / 2) / 2;
        on_usb_wall(label_y, 14.2)
            text("15-16V DC 1A", size = 3.3, font = "Liberation Sans:style=Bold",
                 halign = "center", valign = "center");
        on_usb_wall(label_y, 7.2) polarity_symbol();
    }
}

// ayab-logo-letters.svg and ayab-logo-fills.svg: layers of the AYAB logo, on the
// same 86.33 x 27.97 mm page (from ayab-hardware/ayab-sr-esp32/enclosure).
// Centred on the lid, reading with the USB side on the left.
module logo2d(file) {
    k = logo_w / 86.333885;
    offset(delta = 0.01) // pixels that only touch by a corner would make a non-manifold mesh
        translate([(ix0 + ix1) / 2, (iy0 + iy1) / 2]) scale(k)
            translate([-86.333885 / 2, -27.968893 / 2]) import(file);
}

module lid_logo() {
    top = z_top + lid_t;
    translate([0, 0, top - logo_depth]) linear_extrude(logo_depth + 1) logo2d("ayab-logo-letters.svg");
    translate([0, 0, top - logo_fill_depth]) linear_extrude(logo_fill_depth + 1) logo2d("ayab-logo-fills.svg");
}

// ---------------------------------------------------------------- lid
// Modelled in place (on top of the tray); "print" and "lid" flip it.
module lid() {
    tongue_bottom = z_ard + usb_top;
    difference() {
        union() {
            translate([0, 0, z_top]) linear_extrude(lid_t) outline();

            // tongue closing the USB slot above the connector
            translate([ix0 - wall, usb_y - usb_w / 2 + fit, tongue_bottom])
                cube([wall, usb_w - 2 * fit, z_top - tongue_bottom + eps]);

            // posts holding the shield (and so the Arduino) down on the pegs
            for (p = shield_holes) translate([p.x, p.y, z_sh + post_slack]) {
                cylinder(d = 4.4, h = 3 + eps);
                translate([0, 0, 3]) cylinder(d1 = 4.4, d2 = 6.4, h = z_top - z_sh - post_slack - 3 + eps);
            }

            if (fastening == "snap") at_snaps() snap_arm();

            // end lips: USB side below the slot, DIN side clear of the socket and the post
            translate([ix0, 0, z_top]) end_lip(4, 28);
            translate([ix1, 0, z_top]) mirror([1, 0, 0]) end_lip(41, 50);

            // locating lips along the long walls
            if (fastening == "screws") for (y = [iy0 + fit, iy1 - fit - 1.5])
                translate([6, y, z_top - 3]) cube([ard_w - 12 - 6, 1.5, 3 + eps]);
        }
        if (logo_w > 0) lid_logo();
        if (fastening == "screws") for (p = screws) translate([p.x, p.y, z_top - 1]) cylinder(d = screw_clear_d, h = lid_t + 2);
    }
}

// ---------------------------------------------------------------- mock-ups (preview only)
module arduino_mock(clone_jack_extra = 2) {
    color("teal") translate([0, 0, z_ard_bot]) linear_extrude(pcb_t) difference() {
        polygon([[0, 0], [66.04, 0], [66.04, 2.54], [68.58, 5.08], [68.58, 38.1],
                 [66.04, 40.64], [66.04, 51.82], [64.52, 53.34], [0, 53.34]]);
        for (p = ard_holes) translate(p) circle(d = 3.2);
    }
    color("silver") translate([-6.35, 32.1, z_ard]) cube([16, 12, 10.9]);          // USB-B
    color("dimgray") translate([-1.9 - clone_jack_extra, 3.1, z_ard]) cube([13.3 + clone_jack_extra, 9, 11]); // DC jack
    color("black") for (y = [2.54, 50.8]) translate([18, y - 1.27, z_ard]) cube([46.5, 2.54, 8.5]);
}

module shield_mock() {
    color("saddlebrown") translate([0, 0, z_sh_bot]) linear_extrude(pcb_t) difference() {
        polygon([[0, 0], [66.04, 0], [66.04, 1.27], [68.58, 3.81], [68.58, 38.1],
                 [66.04, 40.64], [66.04, 50.8], [63.5, 53.34], [0, 53.34]]);
        for (p = shield_holes) translate(p) circle(d = 3.2);
    }
    color("dimgray") translate([-4.05, 15.57, z_sh]) cube([14.5, 9, 10.8]);        // DC jack
    color("dimgray") translate([55.4, 6.46, z_sh]) cube([13.55, 21.35, 19.65]);    // DIN
    color("black") translate([41.95, 38.13, z_sh]) cube([20.3, 2.54, 8.5]);        // J7
}

// ---------------------------------------------------------------- output
if (part == "tray") tray();
else if (part == "lid") translate([0, 0, z_top + lid_t]) rotate([180, 0, 0]) lid();
else if (part == "print") {
    tray();
    translate([0, -(iy1 - iy0 + 2 * wall + 5), z_top + lid_t]) rotate([180, 0, 0]) lid();
} else {
    tray();
    %lid();
    arduino_mock();
    shield_mock();
}
