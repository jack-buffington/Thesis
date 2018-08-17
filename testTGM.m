function testTGM()
   close all
   clc


   % Make a set of emitters that all have an activity of one.
   [X, Y] = meshgrid((2:.3:4),(6:.3:7));
   X = reshape(X,numel(X),1);
   Y = reshape(Y,numel(Y),1);
   actualEmitters = [X Y ones(size(X,1))]; 
   


   
   
   
   mapRegion = [10 10 0 0];
   measurementRegion = [10 10 0 0];
   emitterSpacing = .1; % meters
   exclusionRadius = .8; % meters
   renderRegion = mapRegion;
   pixelsPerMeter = 50;
   measurementSpacing = .5; % meters
   measurementJitter = .05; % meters
   
   fluxMap = PSR(actualEmitters,renderRegion, pixelsPerMeter);
   
   % Take some measurements
   [measurements, triangles] = getMeasurements(fluxMap, mapRegion, measurementRegion, ...
    pixelsPerMeter, measurementSpacing, measurementJitter, actualEmitters, exclusionRadius);
 
   estimates = TGM(measurements, triangles);
   
   % Show how well it did
   figure(1)
   s = subplot(1,2,1);
   plot(actualEmitters(:,1), actualEmitters(:,2),'k.');
   s.XLim = [0 10];
   s.YLim = [0 10];
   
   s = subplot(1,2,2);
   plot(estimates(:,1), estimates(:,2),'r.');
   s.XLim = [0 10];
   s.YLim = [0 10];
   
 
end