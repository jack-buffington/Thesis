% testGetEmittersAndGetMeasurements.m
% Creates a set of 'actual' emitters that are used to create another set of emitters
% within a specified readius of them.
% Draws the new emitters as black dots
% Draws the actual emitters as red +'s

close all
clear
clc

% Make a set of emitters that all have an activity of one.
[X, Y] = meshgrid((2:.5:4),(6:.5:7));
X = reshape(X,numel(X),1);
Y = reshape(Y,numel(Y),1);
actualEmitters = [X Y ones(size(X,1),1)]; 


% ##### EMITTERS #####
mapRegion = [10 10 0 0];
emitterSpacing = .1; % meters
exclusionRadius = .8; % meters

emitters = getEmitters(mapRegion, emitterSpacing, actualEmitters, exclusionRadius);


% ##### MEASUREMENTS #####
renderRegion = mapRegion;
pixelsPerMeter = 50;
fluxMap = PSR(actualEmitters,renderRegion, pixelsPerMeter);
measurementRegion = [10 7 0 0];
measurementSpacing = .5; % meters
measurementJitter = .05; % meters

[measurements, triangles] = getMeasurements(fluxMap, mapRegion, measurementRegion, ...
    pixelsPerMeter, measurementSpacing, measurementJitter, actualEmitters, exclusionRadius);
 
 
 
 
 

% Plot out the emitters
figure(1);
s = subplot(1,2,1);
plot(emitters(:,1),emitters(:,2),'.k');
hold on

% Plot out the original emitters
plot(actualEmitters(:,1),actualEmitters(:,2),'+r');


 
% Plot out the measurement locations
plot(measurements(:,1),measurements(:,2),'*b');
s.XLim = [0 10];
s.YLim = [0 10];

%axis equal


% Plot the triangles
s= subplot(1,2,2);
triplot(triangles,measurements(:,1),measurements(:,2),'k')
s.XLim = [0 10];
s.YLim = [0 10];

%axis equal

