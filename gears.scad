// Copyright (c) 2021 Matthew Egeler

// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a
// letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

// TODO: configurable root fillet
// TODO: bevel gear support?
// TODO: accept $fn for gearRes and linear_extrude slices

// Diameter of the circle at which a gear meets it's neighbor gear
// Use this to space out your gears correctly
function pitchCircle(mod, toothCount) = mod*toothCount;

// Length of an arc between the same point on neighboring teeth
function circularPitch(mod) = mod*PI;

// Outer circle of a gear
function addendumCircle(pitchCircle, mod) = pitchCircle+(2*mod);

// Radius difference from pitch circle to the base of each tooth
// 1.25 typically used such that the root is 25% depper than the meshing gear's tooth tops
// for tooth clearance
function dedendum(mod) = 1.25*mod;

// Diameter of a circle intersecting with the base of each tooth
function rootCircle(pitchCircle, dedendum) = pitchCircle-(2*dedendum);

// Height of each tooth
function wholeDepth(mod, dedendum) = mod+dedendum;

// Lowest point at which a mating tooth should reach towards our root
function clearanceCircle(pitchCircle, mod) = pitchCircle-(2*mod);

// The circle of which we draw our involute curves from
function baseCircle(pitchCircle, pressureAngle) = pitchCircle*cos(pressureAngle);

// The angle between each tooth
function angleBetweenTeeth(toothCount) = 360/toothCount;

function herringbone (helix=20) = [-helix, -helix, -helix, -helix, 0, helix, helix, helix, helix];

function circumferencePerTooth(c1rcle, teeth) = (PI*c1rcle)/teeth;

function angle(p1, p2, p3) = 
    let(a = distanceBetweenTwo2dPoints(p1, p2),
        b = distanceBetweenTwo2dPoints(p2, p3),
        c = distanceBetweenTwo2dPoints(p3, p1))
      acos((pow(a,2) + pow(b,2) - pow(c,2))/(2*a*b));

// As degrees
function toothWidthAtBaseCircle(baseCircleRadius, pitchCircleRadius, toothCount, backlashDegrees) =
        let(p1 = involuteAtRadius(baseCircleRadius, pitchCircleRadius, -1, 0),
            p2 = involuteAtRadius(baseCircleRadius, pitchCircleRadius, 1, 0),
            angle = angle(p1, [0,0], p2))
            angle+(angleBetweenTeeth(toothCount)/2)-backlashDegrees;

function distanceBetweenTwo2dPoints(p1, p2) = sqrt(pow(p2[0]-p1[0],2)+pow(p2[1]-p1[1],2)); // TODO pull from utility library?
function toRadians(a) = a*(PI/180);
function toDegrees(a) = a*(180/PI);

function involuteX(baseCircleRadius, t, off) = baseCircleRadius*(cos(t)+(toRadians(t-off)*sin(t)));
function involuteY(baseCircleRadius, t, off) = baseCircleRadius*(sin(t)-(toRadians(t-off)*cos(t)));
function involuteAtRadius(baseCircleRadius, targetRadius, direction=1, off=0) =
  let(t = sqrt(pow((targetRadius/baseCircleRadius),2)-1))
[involuteX(baseCircleRadius,((toDegrees(t))*direction)+off,off), involuteY(baseCircleRadius, ((toDegrees(t))*direction)+off, off)];

function cylinderTwistForHelixAngle(angle, cylinderHeight, cylinderDiameter) =
(360 * ((sin(angle)*cylinderHeight)/(cylinderDiameter*PI)));

function helixTrack(height, teeth, gearModule, helixAngle) = 
let(
  zMove = height,
  circumferenceToTravel = tan(-helixAngle)*zMove,
  gearCircumference = (pitchCircle(gearModule, teeth)*PI),
  circumferenceMMPerDegree = 360/gearCircumference
  )
    (circumferenceMMPerDegree*circumferenceToTravel);

function gearProfile(teeth=10,
                     mod=1,
                     pressureAngle=20,
                     gearRes=4,
                     backlash=0.1,
                     addendumOffset=0,
                     dedendumOffset=0) =

  let (
    circularPitch   = circularPitch(mod),
    pitchCircle = pitchCircle(mod, teeth),

    addendumCircleR  = (addendumCircle(pitchCircle, mod)/2)+addendumOffset,
    dedendum        = dedendum(mod)+dedendumOffset,
    rootCircleR      = rootCircle(pitchCircle, dedendum)/2,
    wholeDepth      = wholeDepth(mod, dedendum),
    clearanceCircle = clearanceCircle(pitchCircle, mod),
    baseCircleR      = baseCircle(pitchCircle, pressureAngle)/2,
    angleBetweenTeeth = angleBetweenTeeth(teeth),

    backlashDegrees = 360*(backlash/(pitchCircle*PI)),
    htwabc = (toothWidthAtBaseCircle(baseCircleR, pitchCircle/2, teeth, backlashDegrees)/2),

    leadingPoints=1,
    trailingPoints=1,

    invStartRadius = (baseCircleR > rootCircleR) ? baseCircleR : rootCircleR,
    vertexCount = ((gearRes+1)*2)+leadingPoints+trailingPoints,

    step = ((addendumCircleR)-invStartRadius)/gearRes
 )
  [for (i = [0:1:teeth-1])
   let(a = angleBetweenTeeth*i)
     for(j = [0:1:vertexCount-1])
       (j >= vertexCount-1) ?
         let(k = j-(gearRes+1)-leadingPoints)
         [cos(htwabc+a)*(rootCircleR),sin(htwabc+a)*(rootCircleR)]
         :
           (j < leadingPoints) ?
           let(k = j)
           [cos(-htwabc+a)*(rootCircleR),sin(-htwabc+a)*(rootCircleR)]
           :
             ((j > gearRes+leadingPoints) ?
              let(k = j-(gearRes+1)-leadingPoints)
              involuteAtRadius(baseCircleR, (addendumCircleR)-(step*k), -1, htwabc+a)
              :
              let(k = j-leadingPoints)
              involuteAtRadius(baseCircleR, (invStartRadius)+(step*k), 1, -htwabc+a))];


function rotateVect(v, a) = [for (i = [0:1:len(v)-1]) [(v[i][0]*cos(a))-(v[i][1]*sin(a)), 
                                                        (v[i][0]*sin(a))+(v[i][1]*cos(a))]];

module gear(teeth=10,
            mod=1,
            pressureAngle=20, 
            gearRes=4, 
            height=10, 
            helixAngle=0, 
            backlash=0.1, 
            addendumOffset=0, 
            dedendumOffset=0) {

  if (helixAngle == 0) {
    translate([0,0,-height/2])
      linear_extrude(height)
      polygon(points=gearProfile(teeth=teeth, mod=mod, pressureAngle=pressureAngle, gearRes=gearRes, backlash=backlash,
                                 addendumOffset=addendumOffset, dedendumOffset=dedendumOffset));
  } else {
    segmentCount = len(helixAngle)-1;
    segmentHeight = height/(len(helixAngle)-1);

    pts = gearProfile(teeth = teeth,
                      mod=mod,
                      pressureAngle=pressureAngle,
                      gearRes=gearRes,
                      backlash=backlash,
                      addendumOffset=addendumOffset,
                      dedendumOffset=dedendumOffset);

    points = [
      for (j = [0:1:segmentCount]) 
        let(twist = rotateVect(pts, 
                               helixTrack(
                                 (height/2)-(segmentHeight*j), 
                                 teeth,
                                 mod,
                                 helixAngle[j])))

          for (i = [0:1:len(twist)-1]) [twist[i][0], twist[i][1],j*segmentHeight]
    ];

    faces = [
      [for (i = [0:1:len(pts)-1]) i],
      [for (j = [len(pts)-1:-1:0]) j+(len(pts)*segmentCount)],

      for (i = [1:1:len(helixAngle)-1])
        for (j = [0:1:len(pts)-1])
          (j == len(pts) -1) ?
            [
            ((len(pts)*(i-1))),
            (len(pts)*(i-1))+j,
            (len(pts)*i)+j,
            ((len(pts)*i)),
            ]  
              :
              [
              ((len(pts)*(i-1))+j+1),
            (len(pts)*(i-1))+j,
            (len(pts)*i)+j,
            ((len(pts)*i)+j+1),
              ] 
    ];

      translate([0,0,-(height/2)])
        polyhedron(points=points, faces=faces, convexity=2);
  }
}
