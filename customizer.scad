// Copyright (c) 2021 Matthew Egeler

// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a
// letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

use <stage.scad>

/* [Layout] */

// The number of planetary gearbox stages
stageCount = 3;

// The height of each stage (mm)
stageHeights = [15,15,15,15,15];

// The gear module (tooth size) for each stage (use -stage# to auto-align planets with the given stage. Beware: recursive.)
gearModule = [1.5, -1, -1, -1, -1];

// The number of planet gears for each stage
planetCounts = [4,4,4,4,4];

// The thickness of the wall for each ring gear (starting at the tooth root)
ringWallThickness = [3,3,3,3,3];

/* [Tooth counts] */

// The tooth count of the sun for each stage (negative tooth count to disable a sun while still allowing auto-calc)
sunTeeth = [10,10,10,10,10];

// The tooth count of the planets for each stage
planetTeeth = [10,10,10,10,10];

// The ring tooth count of the planets for each stage (-1 to auto-calculate from sun and planet counts)
ringTeeth = [-1,-1,-1,-1,-1];

/* [Connections] */

// Flip a stage to 1 to connect to the next gearset planet<->planet. (make sure planet count matches and gear module is auto-calculated to match!)
planetGearConnections = [1,1,0,0,0];

// Flip a stage to 1 to connect to the next stage sun<->sun
sunGearConnections = [0,0,0,0,0];

/* [Tolerances] */

// The gap between each stage (mm)
stageGap = [1,1,1,1,1];

sunBacklash = [0.1,0.1,0.1,0.1,0.1];
planetBacklash = [0.1,0.1,0.1,0.1,0.1];
ringBacklash = [0.1,0.1,0.1,0.1,0.1];


/* [Colors and Rendering] */

// The color of each stage, used only for display purposes (RGB with values 0-1).
stageColors = [
  [0.75,0,0], 
  [0,0.75,0], 
  [0,0,0.75],
  [0.75,0.75,0],
  [0,0.75,0.75],
  [0.75,0,0.75],
];

// Number of subdivisions for gear generation. Reduce for better framerates.
gearResolution = 4; // [1:20]

// Flip to 1 to hide a stage so you can see things
hideStage = [0,0,0,0,0];

for (i = [0:1:stageCount-1]) {
  if (hideStage[i] == 0) {
    translate([0,0,(i > 0) ? addl(stageHeights, c=0, s=i-1) : 0])
      translate([0,0,(stageHeights[i]/2)+((i > 0) ? addl(stageGap, c=0, s=i-1) : 0)])
      color(stageColors[i])
      stage(
        height=(i < len(stageHeights)) ? stageHeights[i] : 5,
        sunTeeth    = sunTeeth[i],
        planetTeeth = planetTeeth[i],
        ringTeeth   = (ringTeeth[i] == -1) ? ringToothCountFromSunAndPlanet(abs(sunTeeth[i]), planetTeeth[i]) : ringTeeth[i],
        gearModule  = getGearModuleForStage(i),
        planetCount = planetCounts[i],
        ringWallThickness = ringWallThickness[i],

        sunBacklash    = sunBacklash[i],
        ringBacklash   = ringBacklash[i],
        planetBacklash = planetBacklash[i],
        gearResolution = gearResolution
        );
  }

  if (planetGearConnections[i] != 0 && (stageCount-1) > i) {
    translate([0,0,addl(stageHeights, c=0, s=i)+((i>0) ? addl(stageGap, c=0, s=i-i) : 0)])
    stageConnectionPlanetToPlanet(planetTeeth[i], planetTeeth[i+1],
                                  sunTeeth[i], sunTeeth[i+1],
                                  getGearModuleForStage(i), getGearModuleForStage(i+1),
                                  planetBacklash[i], planetBacklash[i+1],
                                  stageHeights[i], stageHeights[i+1],
                                  20,
                                  planetCounts[i],
                                  stageGap[i],
                                  gearResolution);
  }
 
  if (sunGearConnections[i] != 0 && (stageCount-1) > i) {
    translate([0,0,addl(stageHeights, c=0, s=i)+((i>0) ? addl(stageGap, c=0, s=i-i) : 0)])
    stageConnectionSunToSun(planetTeeth[i], planetTeeth[i+1],
                            sunTeeth[i], sunTeeth[i+1],
                            getGearModuleForStage(i), getGearModuleForStage(i+1),
                            sunBacklash[i], sunBacklash[i+1],
                            stageHeights[i], stageHeights[i+1],
                            stageGap[i],
                            20,
                            gearResolution);
  }


}

function getGearModuleForStage(s) =
(gearModule[s] > 0) ? gearModule[s]
:
let(stageToMatch = abs(gearModule[s])-1)
gearModuleToFitStage(sunTeeth[stageToMatch],
                     planetTeeth[stageToMatch],
                     getGearModuleForStage(stageToMatch), 
                     abs(sunTeeth[s]),
                     planetTeeth[s]);
   

function addl(list, c = 0, s = 99999) = 
 ((c < len(list)-1) && (s > c)) ? 
 list[c] + addl(list, c + 1, s=s) 
 :
 list[c];


// TODO support auto-calculating different tooth counts other than ring
// TODO error via assert if a setting doesn't have enough elements to cover all stages
// TODO error if tooth counts don't fit correctly
// TODO error if tooth counts can't make even gears
// TODO enable/disable/configure splines
// TODO enable/disable/configure assembly index
// TODO ability to temporarily hide stage/ring
// TODO nema 17 mounting plate and D-shaft hole
// TODO top&bottom blank ring input/output caps
// TODO output diameter and spline dimension of each ring for modeling attachments
// TODO negative gear module lower than -1 should target a specific outer ring diameter
