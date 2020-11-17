// Curve Writing Parametric Module
// https://openhome.cc/eGossip/OpenSCAD/SectorArc.html
height = 0.25;

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
translate([0,0,-0.5])
scale([1,1,1])
linear_extrude(height)
    arc(1.25, [0,90], 0.25, 50);