% This script loads an image file of any size.  Any sources are created from any 
% non-black pixels.  A flux map is rendered for the requested outputRenterRegion. 
% An exclusion map is also created.  This map was used during testing to help figure
% out where to place emitters for the flux match annealing algorithm to use.  I like
% the new method that I am using in testFMAandPSRworkflow.m but I left this in just
% in case someone finds a use for it.  

clear 
clc
close all




fileName = 'testMap.png';
inputPixelsPerMeter = 10;
outputPixelsPerMeter = 50;
initialCoordinate = [0 0];
maxStrength = 1;
width = 10;  
height = 10;
initialX = 0;
initialY = 0;

outputRenderRegion = [width height initialX initialY];


[fluxMap, exclusionZone] = renderFluxMapFromImage(fileName, inputPixelsPerMeter,...
             outputPixelsPerMeter,initialCoordinate, maxStrength,outputRenderRegion);







