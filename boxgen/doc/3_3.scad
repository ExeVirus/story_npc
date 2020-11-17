// Curve Writing Parametric Module
// https://openhome.cc/eGossip/OpenSCAD/SectorArc.html
// Single module, executes all the functionality for most
$fa=0.1; $fs=0.1;

//example node drawn for scale:
color("blue")
    translate([2,-0.5,-0.5])
        cube(1,1,1);

module curve90(Lscale,Wscale, height) {
    resize([Lscale,0,Wscale])   
        cylinder(height, 1,1, false);
}

module sector(radius, angles, fn = 24) {
    r = radius / cos(180 / fn);
    step = -360 / fn;

    points = concat([[0, 0]],
        [for(a = [angles[0] : step : angles[1] - 360]) 
            [r * cos(a), r * sin(a)]
        ],
        [[r * cos(angles[1]), r * sin(angles[1])]]
    );

    difference() {
        circle(radius, $fn = fn);
        polygon(points);
    }
}



module arc(radius, angles, width = 1, fn = 24) {
    difference() {
        sector(radius + width, angles, fn);
        sector(radius, angles, fn);
    }
}
//2x2 90
translate([-7,-10,-0.5])
scale([1,1,1])
linear_extrude(1/4)
    arc(1.25, [0,90], 0.25, 50);

//2x2 180
translate([-4,-10,-0.5])
scale([1,1,1])
linear_extrude(1/4)
    arc(1.25, [0,180], 0.25, 50);

//2x2 270
translate([-1,-10,-0.5])
scale([1,1,1])
linear_extrude(1/4)
    arc(1.25, [0,270], 0.25, 50);

//2x2 360
translate([2,-10,-0.5])
scale([1,1,1])
linear_extrude(1/4)
    arc(1.25, [0,360], 0.25, 50);
    
//3x3 90 --Note the -1.5 offsets for x,z
translate([(-1.5)-7,(-1.5)-7,-0.5])
scale([1,1,1])
linear_extrude(1/4)
    arc(3-0.25, [0,90], 0.25, 50);

//1x2 90
translate([0,0,-0.5])
linear_extrude(1/4)
difference() {
translate([(-1.5)-4,(-1.5)-7,-0.5])
scale([0.5,1,1])
    sector(2, [0, 90], 48);

color("blue")
translate([(-1.5-0.125)-4,(-1.5)-7,-0.5])
scale([0.5,1,1])
    sector(1.75, [0, 90], 48);
};

//1x2 90
linear_extrude(1/4)
difference() {
translate([(-1.5)-1,(-1.5)-7,-0.5])
scale([0.333,1,1])
    sector(3, [0, 90], 48);

color("blue")
translate([(-1.5-0.1666)-1,(-1.5)-7,-0.5])
scale([0.333,1,1])
    sector(2.75, [0, 90], 48);
};

//2x3 90
translate([0,0,-0.5])
linear_extrude(1/4)
difference() {
translate([(-1.5)+3,(-1.5)-7,-0.5])
scale([0.66666,1,1])
    sector(3, [0, 90], 48);

color("blue")
translate([(-1.5-0.083333)+3,(-1.5)-7,-0.5])
scale([0.66666,1,1])
    sector(2.75, [0, 90], 48);
};
    



