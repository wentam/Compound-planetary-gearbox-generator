# Copyright (c) 2021 Matthew Egeler

# This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a
# letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

import cadquery as cq
import math
import logging

# Diameter of the circle at which a gear meets it's neighbor gear
# Use this to space out your gears correctly
def pitchCircle(mod, toothCount): return mod*toothCount

# Length of an arc between the same point on neighboring teeth
def circularPitch(mod): return mod*math.pi

# Outer circle of a gear
def addendumCircle(pitchCircle, mod): return pitchCircle+(2*mod)

# Radius difference from pitch circle to the base of each tooth
# 1.25 typically used such that the root is 25% depper than the meshing gear's tooth tops
# for tooth clearance
def dedendum(mod): return 1.25*mod

# Diameter of a circle intersecting with the base of each tooth
def rootCircle(pitchCircle, dedendum): return pitchCircle-(2*dedendum)

# Height of each tooth
def wholeDepth(mod, dedendum): return mod+dedendum

# Lowest point at which a mating tooth should reach towards our root
def clearanceCircle(pitchCircle, mod): return pitchCircle-(2*mod)

# The circle that we draw our involute curves from
def baseCircle(pitchCircle, pressureAngle): return pitchCircle*math.cos(math.radians(pressureAngle))

def angleBetweenTeeth(toothCount): return 360/toothCount
def herringbone (helix=20): return [-helix, -helix, -helix, -helix, 0, helix, helix, helix, helix]
def circumferencePerTooth(c1rcle, teeth): return (math.pi*c1rcle)/teeth

def angle(p1, p2, p3):
    a = distanceBetweenTwo2dPoints(p1, p2)
    b = distanceBetweenTwo2dPoints(p2, p3)
    c = distanceBetweenTwo2dPoints(p3, p1)

    return math.degrees(math.acos((a**2 + b**2 - c**2)/(2*a*b)))

# TODO pull from utility library?
def distanceBetweenTwo2dPoints(p1, p2): return math.sqrt(((p2[0]-p1[0])**2)+((p2[1]-p1[1])**2))

# As degrees
def toothWidthAtBaseCircle(baseCircleRadius, pitchCircleRadius, toothCount, backlashDegrees):
    p1     = involuteAtRadius(baseCircleRadius, pitchCircleRadius, -1, 0)
    p2     = involuteAtRadius(baseCircleRadius, pitchCircleRadius, 1, 0)
    mangle = angle(p1, [0,0], p2)

    return mangle+(angleBetweenTeeth(toothCount)/2)-backlashDegrees


def rotateVect(v, a): 
    newVect = []
    for i in v:
        newVect.append([(i[0]*cos(a))-(i[1]*sin(a)),
                        (i[0]*sin(a))+(i[1]*cos(a))])

    return newVect;

def involuteX(baseCircleRadius, t, off): 
    return baseCircleRadius*(math.cos(math.radians(t))+(math.radians(t-off)*math.sin(math.radians(t))))

def involuteY(baseCircleRadius, t, off): 
    return baseCircleRadius*(math.sin(math.radians(t))-(math.radians(t-off)*math.cos(math.radians(t))))

def involuteAtRadius(baseCircleRadius, targetRadius, direction=1, off=0):
  t = math.degrees(math.sqrt(((targetRadius/baseCircleRadius)**2)-1))

  return [involuteX(baseCircleRadius,(t*direction)+off,off),
          involuteY(baseCircleRadius,(t*direction)+off,off)]

def helixTrack(height, teeth, gearModule, helixAngle):
    zMove = height
    circumferenceToTravel = math.tan(math.radians(-helixAngle))*zMove
    gearCircumference = (pitchCircle(gearModule, teeth)*math.pi)
    circumferenceMMPerDegree = 360/gearCircumference

    return circumferenceMMPerDegree*circumferenceToTravel

def gearProfile(
        profile,
        teeth=10,
        mod=1,
        pressureAngle=20,
        gearRes=4,
        backlash=0.1,
        addendumOffset=0,
        dedendumOffset=0):

    mpitchCircle       = pitchCircle(mod, teeth)
    addendumCircleR    = (addendumCircle(mpitchCircle, mod)/2)+addendumOffset
    mdedendum          = dedendum(mod)+dedendumOffset
    rootCircleR        = rootCircle(mpitchCircle, mdedendum)/2
    baseCircleR        = baseCircle(mpitchCircle, pressureAngle)/2
    mangleBetweenTeeth = angleBetweenTeeth(teeth)

    backlashDegrees = 360*(backlash/(mpitchCircle*math.pi))
    htwabc = (toothWidthAtBaseCircle(baseCircleR, mpitchCircle/2, teeth, backlashDegrees)/2)

    leadingPoints=1
    trailingPoints=1

    invStartRadius = baseCircleR if (baseCircleR > rootCircleR) else rootCircleR;
    vertexCount = ((gearRes+1)*2)+leadingPoints+trailingPoints

    step = ((addendumCircleR)-invStartRadius)/gearRes

    profile = profile.moveTo(math.cos(math.radians(-htwabc))*rootCircleR,math.sin(math.radians(-htwabc))*rootCircleR)

    for i in range(teeth):
        a = mangleBetweenTeeth*i
        for j in range(leadingPoints):
            if (i > 0):
                profile = profile.lineTo(math.cos(math.radians(-htwabc+a))*rootCircleR,
                                         math.sin(math.radians(-htwabc+a))*rootCircleR)


        xy = involuteAtRadius(baseCircleR, (invStartRadius), 1, -htwabc+a)
        profile = profile.lineTo(xy[0],xy[1])

        splinePts = []
        for j in range(gearRes+1):
            xy = involuteAtRadius(baseCircleR, (invStartRadius)+(step*j), 1, -htwabc+a)
            splinePts.append(xy)

        profile = profile.spline(splinePts, includeCurrent=False)

        xy = involuteAtRadius(baseCircleR, addendumCircleR, -1, htwabc+a)
        profile = profile.lineTo(xy[0],xy[1])

        splinePts = []
        for j in range(1,gearRes+1):
            xy = involuteAtRadius(baseCircleR, (addendumCircleR)-(step*j), -1, htwabc+a)
            splinePts.append(xy)
        profile = profile.spline(splinePts, includeCurrent=True)
        for j in range(trailingPoints):
            profile = profile.lineTo(math.cos(math.radians(htwabc+a))*rootCircleR, math.sin(math.radians(htwabc+a))*rootCircleR) 

    profile = profile.close()

    return profile

points = cq.Workplane("XY")
gearProfile(profile=points);

p1 = cq.Workplane("XY",origin=(0,0,0)).polyline(([0,0,0],[0,0,10]))
p2 = cq.Workplane("XY",origin=(0,6,0)).polyline(([0,0,0],[5,0,5],[0,0,10]))

#p = points.wire().extrude(5);
#p = points.wire().twistExtrude(5,20);
p = points.wire().sweep(p1, auxSpine=p2)

#r = cq.Workplane("XY").box(10,10,10).edges(">Z").fillet(1)
#r = cq.Workplane("XY").polyline(pts).wire().extrude(5)

show_object(p)
show_object(p1)
show_object(p2)































#result = cq.importers.importStep('/home/wentam/Downloads/keyboard-controller.step')
#show_object(result)
