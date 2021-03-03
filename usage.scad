// Copyright (c) 2021 Matthew Egeler

// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a
// letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

use <stage.scad>

planets = 4;
gearRes = 5;

stage0Module = 1.5;
stage0SunTeeth = 10;
stage0PlanetTeeth = 10;
stage0RingTeeth = ringToothCountFromSunAndPlanet(stage0SunTeeth, stage0PlanetTeeth);
stage0Height = 15;
stage0ToleranceToNextStage = 0.5;
stage0RingWallThickness = 3;
stage0RingBacklash = 0.1;


color([0.75,0,0])
stage(gearModule = stage0Module,
      planetCount = planets,
      sunTeeth = stage0SunTeeth,
      planetTeeth = stage0PlanetTeeth,
      ringTeeth = stage0RingTeeth,
      sunBacklash = 0.1,
      planetBacklash = 0.1,
      ringBacklash = stage0RingBacklash,
      ringWallThickness = stage0RingWallThickness,
      height = stage0Height,
      assemblyIndexTop = 0,
      assemblyIndexBottom = 0,
      gearResolution = gearRes);

stage1ToleranceToPreviousStage = 0.5;
stage1Offset=stage0Height+stage1ToleranceToPreviousStage+stage0ToleranceToNextStage;
stage1SunTeeth = 12;
stage1PlanetTeeth = 10;
stage1Height = 15;
stage1Module = gearModuleToFitStage(stage0SunTeeth, stage0PlanetTeeth, stage0Module, stage1SunTeeth, stage1PlanetTeeth);

stage1RingTeeth = ringToothCountFromSunAndPlanet(stage1SunTeeth, stage1PlanetTeeth);

translate([0,0,stage0Height/2])
stageConnectionPlanetToPlanet(stage0PlanetTeeth,
                              stage1PlanetTeeth,
                              stage0SunTeeth,
                              stage1SunTeeth,
                              stage0Module,
                              stage1Module,
                              0.1, // TODO use variable
                              0.1, // TODO use variable
                              stage0Height,
                              stage1Height,
                              20,
                              planets,
                              1, 
                              gearRes);

translate([0,0,stage0Height/2])
stageConnectionSunToSun(stage0PlanetTeeth,
                        stage1PlanetTeeth, 
                        stage0SunTeeth, 
                        stage1SunTeeth, 
                        stage0Module, 
                        stage1Module, 
                        0.1, //TODO
                        0.1, //TODO
                        stage0Height, 
                        stage1Height, 
                        1, 
                        20, 
                        gearRes);

color([0,0.75,0])
translate([0,0,stage1Offset])
stage(gearModule = stage1Module,
      planetCount = planets,
      sunTeeth = stage1SunTeeth,
      planetTeeth = stage1PlanetTeeth,
      ringTeeth = stage1RingTeeth,
      sunBacklash = 0.1,
      planetBacklash = 0.1,
      ringBacklash = 0.1,
      ringWallThickness = 3,
      height = stage1Height,
      assemblyIndexTop = 0,
      assemblyIndexBottom = 0,
      gearResolution = gearRes);


assert(!planetsEvenlySpaced(stage0SunTeeth, ringToothCountFromSunAndPlanet(stage0SunTeeth, stage0PlanetTeeth), planets), 
"Stage 0 planets cannot be spaced evenly with these tooth counts.");

assert(!planetsEvenlySpaced(stage1SunTeeth, ringToothCountFromSunAndPlanet(stage1SunTeeth, stage1PlanetTeeth), planets),
"Stage 1 planets cannot be spaced evenly with these tooth counts.");

stage0_carriageRotationRatio=stage0SunTeeth/(stage0RingTeeth+stage0SunTeeth);
stage0_planetRotationRatio=(stage0SunTeeth-(stage0_carriageRotationRatio*stage0SunTeeth))/stage0PlanetTeeth;

stage01_ratio=((stage0_carriageRotationRatio*stage1RingTeeth)-(stage0_planetRotationRatio*stage1PlanetTeeth))/stage1RingTeeth;

echo(str("Stage 0 sun:",stage0SunTeeth," planet:", stage0PlanetTeeth, " ring:", stage0RingTeeth, " module:", stage0Module));
echo(str("Stage 1 sun:",stage1SunTeeth," planet:", stage1PlanetTeeth, " ring:", stage1RingTeeth));
echo(str("Stage 0 ratio: ",stage0_carriageRotationRatio));
echo(str("Stage 0 planet rotation ratio: ",stage0_planetRotationRatio));
echo(str("Stage 0+1 combined ratio: ",1/stage01_ratio,":1"));

echo(str("Stage 1 ring gear diameter: ", ringGearOD(stage0RingTeeth, stage0Module, stage0RingWallThickness, stage0RingBacklash)));

