// Copyright (c) 2021 Matthew Egeler

// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a
// letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

use <gears.scad>;

// TODO: ability to add a 'lip' - a slightly taller ring than the planetary gears.
// This makes load attachment tolerances easier
//
// TODO: ring chamfer+fillet support
//
// TODO: spline side chamfer+fillet support (improves tolerances)
//
// TODO: Configurable pressure angle
//
// TODO: configurable helix angle
//
// TODO: ring assembly slit should also be in spline
//
// TODO: user should be able to offset split
//
// TODO: add ability to target a specific diameter via a util function (diameter to module)
//
// TODO: support attaching to the next stage via sun or ring gear as well
//
// TODO: assembly index adapt to number of planets
//
// TODO: stage-level validation (does the ring tooth count match planets and sun?)
//
// TODO: asymmetric gearboxes possible? (different planet sizes)
//
// TODO: move stuff to utility library
//
// TODO: namespace stuff C-style?
//
// TODO: ability to exclude sun for a stage - and pass through a cylinder to reach stage after
//
// TODO: better loft?
// =====
// UTIL
// =====


// TODO some of these can now be pulled from gears.scad probably
function pitchDiameter(teeth, gearModule) = teeth*gearModule;
function gearDiameter(teeth, gearModule) = (teeth+2) / 
                                           (teeth/pitchDiameter(teeth, gearModule));

function gearCircumference(teeth, gearModule) = gearDiameter(teeth, gearModule)*PI;
function pitchCircleCircumference(teeth, gearModule) = pitchDiameter(teeth, gearModule)*PI;

function planetsEvenlySpaced(sunToothCount, ringToothCount, planetCount)
  = !(round((sunToothCount+ringToothCount)/planetCount) - 
      ((sunToothCount+ringToothCount)/planetCount) == 0);

function ringToothCountFromSunAndPlanet(sunToothCount, planetToothCount) 
  = sunToothCount+(planetToothCount*2);

function gearModuleToFitStage(fitSunTeeth, fitPlanetTeeth, fitToModule, ourSunTeeth, ourPlanetTeeth)
= ((fitSunTeeth+fitPlanetTeeth)/(ourSunTeeth+ourPlanetTeeth))*fitToModule;

function ringGearOD(ringTeeth, gearModule, ringWallThickness, ringBacklash) =
gearDiameter(ringTeeth, gearModule)+ringWallThickness+((ringBacklash)*2);

// ====== END UTIL ======


// ==============
// COMPONENTS
// ==============

module sun(teeth, planetTeeth, gearModule, height, backlash, gearRes) {
  rotate([0,0,((planetTeeth % 2 == 0) ? ((360/teeth)/2) : 0)])
  gear(teeth=teeth,
            mod=gearModule, 
            height=height,
            helixAngle=herringbone(helix=20),
            backlash=backlash, 
            gearRes=gearRes);
}

module ring(height, ringTeeth,
            ringBacklash, gearModule, splitOffset,
            ringWallThickness, gearRes) {

  ringGearDiameter = ringGearOD(ringTeeth, gearModule, ringWallThickness, ringBacklash);

  difference() {

    cylinder(d=ringGearDiameter, h=height-0.01, center=true, $fn=100);
   gear(teeth=ringTeeth,
              mod=gearModule,
              height=height, 
              helixAngle=[20,0,-20],
              backlash=-ringBacklash, 
              addendumOffset=ringBacklash, 
              dedendumOffset=-(ringBacklash*6), 
              gearRes=gearRes);

    translate([splitOffset,0,0]) split();
  }

  module split(splitThickness=0.4) {
    translate([0,0,0])
      difference() {
        scale([0.4,1,1])
          rotate([0,45,0])
          cube([100,100,100]);

        translate([splitThickness,-0.1,0])
          scale([0.4,1,1])
          rotate([0,45,0])
          cube([100,101,100]);

      }
  }
}

function distanceBetweenTwo2dPoints(p1, p2) = sqrt(pow(p2[0]-p1[0],2)+pow(p2[1]-p1[1],2));

function distanceOfClosestPointInVector(p, vec) = 
  min([for(i = [0:1:len(vec)-1]) distanceBetweenTwo2dPoints(p, vec[i])]);

// Will be returned as a list of all points that match the closest distance
function closestToPointInVector(p, vec) = 
  let(distance = distanceOfClosestPointInVector(p,vec))
  [for(i = [0:1:len(vec)-1]) if (distanceBetweenTwo2dPoints(p, vec[i]) == distance) i];
  
module loft(pts1, pts2, height) {
  topPts    = (len(pts1) >  len(pts2))  ? pts1 : pts2;
  bottomPts = (len(pts1) <= len(pts2)) ? pts1 : pts2;

  topPtCount    = len(topPts);
  bottomPtCount = len(bottomPts); 

  closestBottomPt = closestToPointInVector(bottomPts[0], topPts)[0];

  points = [
    // Top points
    for (j = [0:1:(topPtCount-1)])
      [topPts[j][0],
      topPts[j][1],
      //topPts[j][2]],
      (len(pts1) > len(pts2)) ? 0 : height],

      // Bottom points
      for (j = [0:1:(bottomPtCount-1)])
        [bottomPts[j][0],
        bottomPts[j][1],
        //bottomPts[j][2]],
        (len(pts1) <= len(pts2)) ? 0 : height ]
  ];

  faces = [
    // All top points as one face
    [for (i=[topPtCount-1:-1:0]) i],

    // All bottom points as one face
    [for (i=[0:1:(bottomPtCount-1)]) i+topPtCount],

    // Stitch top points to bottom points, using the ratio between topPtCount and bottomPtCount
    // to track the two surfaces evenly
    for (i = [0 : topPtCount - 1])
      let(tp = (i+closestBottomPt)%topPtCount,
          targetBottomPoint1 = floor((i+1)*(bottomPtCount/topPtCount)),
          targetBottomPoint2 = floor(i*(bottomPtCount/topPtCount)))
        if (targetBottomPoint1 != targetBottomPoint2 &&
            targetBottomPoint1 < bottomPtCount &&
            targetBottomPoint2 < bottomPtCount)
          let(tp = (i+closestBottomPt)%topPtCount)
            [tp, (tp+1)%topPtCount, topPtCount+targetBottomPoint1, topPtCount+targetBottomPoint2]
        else
          let(tp = (i+closestBottomPt)%topPtCount)
            [tp, (tp+1)%topPtCount, topPtCount+floor(i*(bottomPtCount/topPtCount))],

            // Final face to cover corner-case
            [0+closestBottomPt, 
            topPtCount,
            topPtCount+bottomPtCount-1],
  ];

  polyhedron(points = points, faces = faces);
}

// Planet positioning utilities

function planetOffsetFromSun(sunTeeth, planetTeeth, gearModule) =
(let(sunPitchDiameter = pitchDiameter(sunTeeth, gearModule),
     planetPitchDiameter = pitchDiameter(planetTeeth, gearModule))
((sunPitchDiameter/2)+(planetPitchDiameter/2)));

function sunPlanetRotation(i, planetCount) = (i*(360/planetCount));
function localPlanetRotation(i, planetTeeth, planetCount, sunTeeth) = 
(let(interval = 360/planetCount,
    toothAngle = 360/planetTeeth,
    sunToothAngle = 360/sunTeeth,
    sunTeethCovered = (interval*i)/sunToothAngle)

  (sunTeethCovered*toothAngle));

function rotatePtMatrix(a) = 
		  [[1,0,0],[0,cos(a[0]),-sin(a[0])],[0,sin(a[0]),cos(a[0])]]
		* [[cos(a[1]),0,sin(a[1])],[0,1,0],[-sin(a[1]),0,cos(a[1])]]
		* [[cos(a[2]),-sin(a[2]),0],[sin(a[2]),cos(a[2]),0],[0,0,1]];

function rotateVect(v, a) = [for (i = [0:1:len(v)-1]) rotatePtMatrix(a) * v[i]];

function rotateVect2d(v, a) = [for (i = [0:1:len(v)-1]) [(v[i][0]*cos(a))-(v[i][1]*sin(a)), 
                                                        (v[i][0]*sin(a))+(v[i][1]*cos(a))]];

function helixTrack(height, planetTeeth, gearModule, helixAngle) = 
let(
  zMove = (height/2),
  circumferenceToTravel = tan(20)*zMove,
  gearCircumference = pitchCircleCircumference(planetTeeth, gearModule),
  circumferenceMMPerDegree = 360/gearCircumference
  )
    (circumferenceMMPerDegree*circumferenceToTravel);

// Stage connections
// TODO: backlash
module stageConnectionPlanetToPlanet(lowerStagePlanetToothCount,
                                     upperStagePlanetToothCount,
                                     lowerStageSunToothCount,
                                     upperStageSunToothCount,
                                     lowerStageGearModule,
                                     upperStageGearModule,
                                     lowerStagePlanetBacklash,
                                     upperStagePlanetBacklash,
                                     lowerStageHeight,
                                     upperStageHeight,
                                     helixAngle,
                                     planetCount,
                                     height,
                                     gearResolution
                                     ) {

  // Iterate over planets and build a connector for each
  for (i = [0:1:planetCount-1])  {
    rotate([0,0,-sunPlanetRotation(i, planetCount)])
    translate([planetOffsetFromSun(lowerStageSunToothCount, lowerStagePlanetToothCount, lowerStageGearModule),0,0])
    planetConnector(i);
  }

  module planetConnector(i) {
    // Generate 2d cross-sections
    lowerPts = gearProfile(teeth=lowerStagePlanetToothCount,
                           backlash=lowerStagePlanetBacklash,
                           mod=lowerStageGearModule,
                           gearRes=gearResolution); 

    upperPts = gearProfile(teeth=upperStagePlanetToothCount,
                           backlash=upperStagePlanetBacklash,
                           mod=upperStageGearModule,
                           gearRes=gearResolution);

    // Figure out how far to rotate to compensate for helix angle
    ht = helixTrack(lowerStageHeight, lowerStagePlanetToothCount, lowerStageGearModule, helixAngle);
    htu = helixTrack(upperStageHeight, upperStagePlanetToothCount, upperStageGearModule, helixAngle);

    // Rotationally line up our connector with our target planet gears
    lowerStageRotate = (localPlanetRotation(i, lowerStagePlanetToothCount, planetCount, lowerStageSunToothCount)+ht);
    upperStageRotate = (localPlanetRotation(i, upperStagePlanetToothCount, planetCount, upperStageSunToothCount)+htu);

    // Loft our 2d cross-sections at the correct angles
    loft(rotateVect2d(lowerPts, 
                    -lowerStageRotate),
         rotateVect2d(upperPts, 
                    -upperStageRotate),
          height);
  }
};

module stageConnectionSunToSun(lowerStagePlanetToothCount,
                               upperStagePlanetToothCount,
                               lowerStageSunToothCount,
                               upperStageSunToothCount,
                               lowerStageGearModule,
                               upperStageGearModule,
                               lowerStageSunBacklash,
                               upperStageSunBacklash,
                               lowerStageHeight,
                               upperStageHeight,
                               height,
                               helixAngle,
                               gearResolution) {

  // Generate 2d cross-sections
  lowerPts = gearProfile(teeth=lowerStageSunToothCount,
                  backlash=lowerStageSunBacklash, 
                  mod=lowerStageGearModule, 
                  gearRes=gearResolution); 

  upperPts = gearProfile(teeth=upperStageSunToothCount, 
                  backlash=upperStageSunBacklash, 
                  mod=upperStageGearModule, 
                  gearRes=gearResolution); 


  // Figure out how far to rotate to compensate for helix angle
  ht = helixTrack(lowerStageHeight, lowerStageSunToothCount, lowerStageGearModule, helixAngle);
  htu = helixTrack(upperStageHeight, upperStageSunToothCount, upperStageGearModule, helixAngle);

  // Line up our sun gear with our target sun gears 
  lowerStageRotate = (lowerStagePlanetToothCount % 2 == 0) ? ((360/lowerStageSunToothCount)/2) : 0;
  upperStageRotate = (upperStagePlanetToothCount % 2 == 0) ? ((360/upperStageSunToothCount)/2) : 0;

  loft(rotateVect2d(lowerPts, 
                  lowerStageRotate+ht),
       rotateVect2d(upperPts, 
                  upperStageRotate+htu),
                  height);
}

module planets(planetTeeth, planetCount, sunTeeth, backlash, gearModule, height, 
//connectionCylinder,
 //              topExtension, bottomExtension,
gearRes) {
  for (i = [0:1:planetCount-1])  {
    planet(planetTeeth,
           sunTeeth,
           backlash,
           gearModule,
           height,
           i);
  } 

  module planet(planetTeeth,
                sunTeeth,
                planetBacklash, 
                gearModule, 
                height, 
                i) {

    rotate([0,0,-sunPlanetRotation(i, planetCount)])
      translate([planetOffsetFromSun(sunTeeth, planetTeeth, gearModule),0,0])
      rotate([0,0,-localPlanetRotation(i, planetTeeth, planetCount, sunTeeth)])

      gear(teeth=planetTeeth, mod=gearModule, height=height, helixAngle=herringbone(helix=-20),
                backlash=planetBacklash, gearRes=gearRes);

  }
}

module stageAssemblyIndex(depth, stageHeight) {
  // Assembly index marks
  thickness=1.2;

  translate([-50,-thickness/2,-depth+stageHeight/2])
    cube([100,thickness,10]);

  translate([-thickness/2,-50,-depth+stageHeight/2])
    cube([thickness,100,10]);
}

// Splines
module stageRingSplines(gearModule, ringTeeth, ringWallThickness, ringBacklash, height) {
  // Assembly index marks
  thickness=7;
  depth=1;

  length = ringGearOD(ringTeeth, gearModule, ringWallThickness, ringBacklash)+depth;

  rotate([0,0,45/2])
    difference () {
      translate([0,0,-height/2])
        union() {
          translate([-length/2,-thickness/2,0])
            cube([length,thickness,height]);

          translate([-thickness/2,-length/2,0])
            cube([thickness,length,height]);

          rotate([0,0,45])
            union() {
              translate([-length/2,-thickness/2,0])
                cube([length,thickness,height]);

              translate([-thickness/2,-length/2,0])
                cube([thickness,length,height]);
            }
        }

      translate([0,0,-0.5-height/2])
        cylinder(d=length-depth, h=height+1, $fn=40);
    }
}

module stage(
  // General config
  gearModule= 1.5,     // Defines tooth size
  sunTeeth  = 10,      // Quantity of sun teeth
  ringTeeth = 30,      // Quantity of ring teeth
  planetTeeth=10,      // Quantity of planet teeth
  planetCount=4,       // Quantity of planets
  ringWallThickness=3, // Thickness of wall around the ring gear
  height=15,           // Height of the stage

  // Tolerances
  sunBacklash=0.1,    // Gear meshing tolerance
  ringBacklash=0.1,   // ^^^^^
  planetBacklash=0.1, // ^^^^^

  // Assembly guides
  assemblyIndexTop=0,
  assemblyIndexBottom=0,

  // Output tuning
  gearResolution=4,
  ) {
  difference() {
    union() {
      stageRingSplines(gearModule, ringTeeth, ringWallThickness, ringBacklash, height);

      if (ringTeeth > 0)
      ring(height, ringTeeth, ringBacklash, gearModule,2, ringWallThickness, gearResolution);

      if (planetTeeth > 0)
      planets(planetTeeth, planetCount, abs(sunTeeth), planetBacklash, gearModule, height,
gearResolution);

      if (sunTeeth > 0)
      sun(sunTeeth, planetTeeth, gearModule,height, sunBacklash, gearResolution);
    }

    if (assemblyIndexTop)                    stageAssemblyIndex(assemblyIndexTop, height);
    if (assemblyIndexBottom) mirror([0,0,1]) stageAssemblyIndex(assemblyIndexBottom, height);
  }
}
