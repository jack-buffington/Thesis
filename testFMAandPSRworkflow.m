function testFMAandPSRworkflow()

   % This file operates as follows:
   % To avoid packaging this code with large image files, I have made it so that it
   % renders a dense flux map to 'take measurements' from.
   % It does this first.
   % It comes up with a set of locations where the flux will be measured.
   % Next it 'takes the measurements'.
   % It then passes these measurements to the flux match annealing algorithm.
   % To finish up, it draws a comparison of the original and estimated source maps as
   % well as the original and estimated flux maps.
   close all
   clc


   % Make a set of emitters that all have an activity of one.
   [X, Y] = meshgrid((2:.3:4),(6:.3:7));
   X = reshape(X,numel(X),1);
   Y = reshape(Y,numel(Y),1);
   actualEmitters = [X Y ones(size(X,1))]; 
   
   renderRegion = [10 10 0 0];
   
   % Render a dense flux map from these emitters
   pixelsPerMeter = 50;
   actualFluxMap = PSR(actualEmitters, renderRegion, pixelsPerMeter);
   
   
   
   mapRegion = [10 10 0 0];
   measurementRegion = [10 10 0 0];
   
   emitterSpacing = .1; % meters
   exclusionRadius = .8; % meters
   renderRegion = mapRegion;
   pixelsPerMeter = 50;
   fluxMap = PSR(actualEmitters,renderRegion, pixelsPerMeter);
   measurementSpacing = .5; % meters
   measurementJitter = .05; % meters
   
   % Take some measurements
   [measurements, ~] = getMeasurements(fluxMap, mapRegion, measurementRegion, ...
    pixelsPerMeter, measurementSpacing, measurementJitter, actualEmitters, exclusionRadius);
 
   
   
   % Place some emitters
   emitters = getEmitters(mapRegion, emitterSpacing, actualEmitters, exclusionRadius);

   
  
   
   % Flux match annealing
   numberOfIterations = 30000;
   maxAllowablePercentageIncrease = .2;
   acceptanceFrequency = 8;
   sigmaConstant = 20;
   estimatedEmitters = FMA(numberOfIterations, emitters, measurements, renderRegion, ...
                  maxAllowablePercentageIncrease, acceptanceFrequency, sigmaConstant);

   
               
               
   % Render the estimated flux map
   estimatedFluxMap = PSR(estimatedEmitters, renderRegion, pixelsPerMeter);
               
               
   
   % Display the results
   figure(1);
   subplot(2,2,1);
   map = renderEmitters(renderRegion, actualEmitters, 1, .1);
   imshow(map);
   title('Actual emitters');
   
   subplot(2,2,2);
   map = renderEmitters(renderRegion, estimatedEmitters, 1, .1);
   imshow(map);
   title('Estimated emitters');
   
   subplot(2,2,3);
   imshow(actualFluxMap);
   title('Actual flux');
   
   subplot(2,2,4);
   imshow(estimatedFluxMap);
   title('Estimated flux');
   
   
   

end



% ############################
% ##### HELPER FUNCTIONS #####
% ############################

function map = renderEmitters(mapRegion, emitters, maxValue, emitterSpacing)
% makes a map that shows emitter activities where maxValue is represented by a value
% of 1.  
% Emitters are ideally in a grid but don't have to be.
% emitterSpacing is the width of each pixel in meters for the map

   mapWidth = mapRegion(1);
   mapHeight = mapRegion(2);
   mapStartX = mapRegion(3);
   mapStartY = mapRegion(4);
   
   pixelsWidth = floor(mapWidth / emitterSpacing);
   pixelsHeight = floor(mapHeight / emitterSpacing);
   
   map = zeros(pixelsHeight,pixelsWidth);
   
   for I = 1:size(emitters,1)
      mapX = round((emitters(I,1) - mapStartX)/emitterSpacing);
      mapY = round((emitters(I,2) - mapStartY)/emitterSpacing);
      map(mapY,mapX) = map(mapY,mapX) + emitters(I,3);
   end
   
   map = map/maxValue;
   map(map > 1) = 1;
end



% function makeMapFromEmitters(revisionName,mapNumber)
% 
%    % This script takes a set of emitters and turns them into a map showing the
%    % total activity of the emitters for any given location.   
% 
%    originalPixelsPerMeter = 10;
%    outputPixelsPerMeter = 4;
% 
%    brightnessScaleFactor = 1/((originalPixelsPerMeter / outputPixelsPerMeter)^2);
% 
%    mapWidth = 10;
%    mapHeight = 10;
% 
%    desiredNumberOfEmitters = 2000;
% 
%    squareArea = mapWidth * mapHeight; % in square meters
% 
%    areaPerEmitter = squareArea / desiredNumberOfEmitters; % in square meters
% 
%    distancePerEmitter = sqrt(areaPerEmitter); % in meters (edge length of square that contains it)
% 
%    emittersWidth = floor(mapWidth / distancePerEmitter);
%    emittersHeight = floor(mapHeight / distancePerEmitter);
% 
% 
%    fileName = sprintf('results/%s_emitters.mat',revisionName);
% 
%    imageFile = sprintf('../emitterMaps/map%02d.png',mapNumber);
%    fudgeFactor = 1.5;
% 
% 
% 
%    % Assumes a 44x45 grid of emitters
%    originalPixelsPerMeter = 10;
% 
%    % pixelsWidth = 44;
%    % pixelsHeight = 45;
% 
%    pixelsWidth = emittersWidth;
%    pixelsHeight = emittersHeight;
% 
%    originalWidth = 10;
%    originalHeight = 10;
% 
%    numberOfOriginalPixels = originalWidth * originalHeight * originalPixelsPerMeter^2;
%    numberOfNewPixels = pixelsWidth * pixelsHeight;
% 
%    fluxScaleFactor = numberOfOriginalPixels/numberOfNewPixels;
% 
% 
% 
% 
%    load(fileName);
%    image = imread(imageFile);
% 
%    % Quantize the emitter coordinates into pixel coordinates
%    emitters(:,1:2) = emitters(:,1:2) .* repmat([pixelsHeight/originalHeight pixelsWidth/originalWidth],size(emitters,1),1);
%    emitters(:,1:2) = int32(emitters(:,1:2) - .5);
% 
%    % put those values into the correct locations
%    pixelMap = zeros(pixelsHeight, pixelsWidth);
% 
%    for I = 1: size(emitters,1)
%       X = emitters(I,1);
%       Y = emitters(I,2);
%       strength = emitters(I,3);
%       pixelMap(Y,X) = pixelMap(Y,X) + strength;
%    end
% 
%    pixelMap = (pixelMap / fluxScaleFactor) * fudgeFactor;
%    pixelMap = imgaussfilt(pixelMap,1);
% 
%    
%    % ###################################
%    % Build the figure used in the slides
%    % ###################################
%    figure(5)
%    fSize = 14;
%    
%   
%    sp = subplot(2,3,1);
% 
%    imshow(image)
%    t = title('Actual source map');
%    t.FontSize = 14;
%    
%    sp = subplot(2,3,4);
% 
%    imshow(pixelMap)
%    t = title('Estimated source map');
%    t.FontSize = 14;
%    
%    
% 
%    figure(6)
%    subplot(1,2,1)
%    imshow(image);
% 
%    subplot(1,2,2)
%    imshow(pixelMap);
%    filename = sprintf('results/%s_emitterComparison.png',revisionName);
%    saveas(6,filename);
% end



% function [X, Y, tri] = makeMeasurementGridAndTriangles(rows,cols, width, height)
%    % This function creates a grid of measurement locations and returns the locations 
%    % and a triangulation of them.  
%    % The locations returned represent measurement locations and have some positional
%    % jitter in them.
% 
%    % Rows/cols describe the grid of sample points
%    % width/height describe the pixel array that the points will be sampled from.
%    % X,Y,width,& height are all in pixels.
%   
%    
%    
%    jitterSize = 7;
%    
%    % set up some intial variables
%    numPoints = rows*cols;
%    xSpacing = floor((width - jitterSize- 1)/(cols-1));
%    ySpacing = floor((height - jitterSize - 1)/(rows-1)); 
% 
%    X = zeros(numPoints,1);
%    Y = zeros(numPoints,1);
% 
%    yPos = 0;
%    index = 1;
%    for I = 1:rows
%       xPos = 0;
%       for J = 1:cols
%          X(index,1) = xPos + 1;
%          Y(index,1) = yPos + 1;
%          xPos = xPos + xSpacing;
%          index = index+1;
%       end
%       yPos = yPos + ySpacing;
%    end 
% 
%    if jitterSize ~= 0
%       X = X + randi(jitterSize,size(X,1),1);
%       Y = Y + randi(jitterSize,size(Y,1),1); 
%    end
% 
%    % at this point it can do a triangulation but the issue is that you get 
%    % thin sliver triangles at the edges so I'm putting in some extra points
%    % to force the edge points to connect to it instead
% 
%    % Note that this strategy isn't perfect and that you may want to find another
%    % method to detect edge triangles.   A likely method would be to check the areas
%    % of all triangles and get rid of ones that fall below some threshold.
% 
%    X = [X; -width*.1; width*1.1; width/2; width/2];
%    Y = [Y; height/2; height/2; -height*.1; height*1.1];
% 
%    tri = delaunay(X,Y);  % This returns the index of the points for each triangle
% 
%    
%    % Now remove the extra points and the triangles that contain them.  
%    badTris = tri == size(X,1);
%    badTris1 = sum(badTris')';
%    badTris = tri == size(X,1)-1;
%    badTris2 = sum(badTris')';
%    badTris = tri == size(X,1)-2;
%    badTris3 = sum(badTris')';
%    badTris = tri == size(X,1)-3;
%    badTris4 = sum(badTris')';
%    
%    allBadTris = badTris1 + badTris2 + badTris3 + badTris4 > 0;
%    tri = tri(~allBadTris,:);
% 
% 
%    X = X(1:size(X,1)-4);
%    Y = Y(1:size(Y,1)-4);
% 
% end

% function theColors = makeLookupTable()
%    % make a color lookup table
%    
%    % this is a simple color gradient starting at red and ending in violet
%    theColors = zeros(256,3);
%    
%    for I = 1:52
%       theColors(I,:) = [1 I/52 0];
%    end
%    
%    for I = 1:51
%       theColors(I+52,:) = [1 - I/51 1 0];
%    end
%    
%    for I = 1:51
%       theColors(I+103,:) = [0 1 I/51];
%    end
%    
%    for I = 1:51
%       theColors(I+154,:) = [0 1 - I/51 1];
%    end
%    
%    for I = 1:51
%       theColors(I+205,:) = [I/51 0 1];
%    end
%    
% end
