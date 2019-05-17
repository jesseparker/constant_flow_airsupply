// Experimental <<SIN*U*SOID*AL>> Venturi for Flow Measurement
// Seems like a sine wave should be good...
// Copyright <senorjp@gmail.com> April 2019
//

// Says "bolt" but designed for a #12 pan-head wood screw
bolthole_thread_d=2.5;
bolthole_shank_d=4;
bolthole_head_d=6.5;
bolthole_length=12;


// This section describes the coupling to the fan

bead_d=39.2;
bead_w=3.5;
bead_behind=1;
bead_h=1.7;
nozzle_d=33;
nozzle_l=12;
shell_t=2;
smidge=0.01;

// These settings are from my original sinusoidal venturi
// Whole part or split for printing
split = 1; // [1:Split,0:Whole]
// Outside (unrestricted) Diameter
od=nozzle_d; // [10:300]
// Area ratio (higher number smaller throat)
ratio=3; // [1:20]
// Overall length
length=70; // [20:400]

// Diameter of tap hole in throat
tap_d=8; // [0:50]
// Tolerance for mating pins
pin_tol=1; // [0:2]
// Smoothness
$fs=.7; // [.1:5]
$fa=5;
/* [Hidden] */

pi=3.14159;
step=10; // smoothness of sine wave
big_a=pi*pow(od/2,2);
small_a=big_a/ratio;
id=2*sqrt(small_a/pi);
height=(od-id)/4; // we are looking at the sine wave from top to bottom
//height=-100;
oa_length=length+nozzle_l+bead_w+shell_t+tap_d*2;

// Position of screw holes
case_bolts = [
[bead_d/2+shell_t/2+.5, -length/2-tap_d/2-tap_d-nozzle_l+bead_w],
[-bead_d/2-shell_t/2-.5,-length/2-tap_d/2-tap_d-nozzle_l+bead_w],
[od/2, 0],
[-od/2, 0],
];

//case_bolts= []; // Uncomment this line to turn off screw holes e.g. whole part

module bolthole() {
    len=40;
    translate([0,0,len/4+bolthole_length/2])
    cylinder(r=bolthole_head_d/2, h=len/2, center=true);

    translate([0,0,bolthole_length/4])
    cylinder(r=bolthole_shank_d/2, h=bolthole_length/2+smidge, center=true);

    translate([0,0,-len/4])
    cylinder(r=bolthole_thread_d/2, h=len/2, center=true);
}

module bolthole_boss() {
    cylinder(r=bolthole_head_d/2, h=bolthole_length+smidge*2, center=true);
}

module boltholes() {
    rotate(-90,[1,0,0])
    for (i = case_bolts) {
        translate([i[0],i[1],0])
        bolthole();
    }
}
module bosses() {
    rotate(-90,[1,0,0])
    for (i = case_bolts) {
        translate([i[0],i[1],0])
        bolthole_boss();
    }
}

module fan_nozzle () {
    translate([0,0,nozzle_l+bead_w/2])
    rotate_extrude()
    translate([bead_d/2-bead_w/2,0])
    circle(r=bead_w/2);
    translate([0,0,nozzle_l+bead_w/2])
    cylinder(r=bead_d/2-bead_h+smidge, h=bead_w+smidge, center=true);
    translate([0,0,nozzle_l+bead_w+bead_behind/2])
    cylinder(r=bead_d/2-bead_h, h=bead_behind*4, center=true);
    translate([0,0,nozzle_l/2])
    cylinder(r2=bead_d/2-bead_h, r1=nozzle_d/2, h=nozzle_l+smidge, center=true);
}

module nozzle_blank() {
    translate([0,0,nozzle_l+bead_w/2])
    rotate_extrude()
    translate([bead_d/2-bead_w/2,0])
    circle(r=bead_w/2+shell_t);
    translate([0,0,nozzle_l+bead_w/2])
    cylinder(r=bead_d/2-bead_h+smidge+shell_t, h=bead_w+smidge, center=true);
    translate([0,0,nozzle_l+bead_w+bead_behind/2])
    cylinder(r=bead_d/2-bead_h+shell_t, h=bead_behind, center=true);
    translate([0,0,nozzle_l/2])
    cylinder(r2=bead_d/2-bead_h+shell_t, r1=nozzle_d/2+shell_t, h=nozzle_l, center=true);

}

module nozzle_shell() {
    difference(){
        union() {
            nozzle_blank();
            
            // this piece is a flat foot mainly for printing the part split
            // but also for making the tap holes deeper
            translate([0,0,-oa_length/2+nozzle_l+bead_w+shell_t])
                difference() {
                    cube([od/2+shell_t*2, bead_d+shell_t*2,  oa_length], center=true);
                    cylinder(r=od/2+shell_t-smidge, h=oa_length+smidge, center=true);
                }
        }
        fan_nozzle();
     }
}


module venturi() {

difference() {
    union() {

    rotate_extrude( convexity=10)
    translate([height+id/2,-length/2])
    // sine wave is created as a polygon
polygon(
        [
        //[height+shell_t,-tap_d/2-tap_d],
        [height+shell_t,-tap_d/2], // Add in the thickness of the shell
        
// CODE FOR OPENSCAD-NIGHTLY
        for (a = [0 : step : 180])
        [ height*sin(a+90) , a * (length/360)-tap_d/2],
        for (a = [180 : step : 360])
        [ height*sin(a+90) , a * (length/360)+tap_d/2],

        [height,length+tap_d/2+tap_d], // Add length for the upstream tap
        
        [height+shell_t,length+tap_d/2+tap_d]


//////// CODE FOR CUSTOMIZER ///////////////////////////
// Not sure why, but customizer and openscad 2014.03 give
// syntax error on the for loops, above.
// As a work-around, the for loop is evaluated and
// included, below.  This is the bash script to do that:
/*
step=10
a=0
while [ $a -le 180 ]; do
  echo "[ height*sin($a+90) , $a * (initial_length/360)-tap_d/2],"
  a=$(( $a+$step ))
done
while [ $a -le 360 ]; do
  echo "[ height*sin($a+90) , $a * (initial_length/360)+tap_d/2],"
  a=$(( $a+$step ))
done

*/
]
);

// Fan coupling
translate([0,0,length/2+tap_d/2+tap_d-smidge])
nozzle_shell();
bosses();

}


    // Throat Tap
    translate([0,-od/2,0])
    rotate(90,[1,0,0])
    cylinder(r=tap_d/2, h=od, center=true);

    // Upstream Tap
    translate([0,-od/2,length/2+tap_d])
    rotate(90,[1,0,0])
    cylinder(r=tap_d/2, h=od, center=true);

    boltholes();
}



}

// Split the part for printing a la open face sandwich
module venturi_top() {
difference() {
    venturi();
    translate([0,length,0])
    cube([length*2,length*2,length*2], center=true);
}

}

module venturi_bottom() {
difference() {
    venturi();
    translate([0,-length,0])
    cube([length*2,length*2,length*2], center=true);

}
}

module venturi_pair_print() {

    x=-(tap_d+nozzle_l+bead_w+shell_t)/2;
    translate([bead_d/2+3,-x,bead_d/2+shell_t])
    rotate(90,[1,0,0])
    venturi_top();

    translate([-bead_d/2-3,x,bead_d/2+shell_t])
    rotate(-90,[1,0,0])
    venturi_bottom();
}
//venturi_top();
//venturi_bottom();
if (split == 1) {
    venturi_pair_print();
}
else {
    venturi();
}
