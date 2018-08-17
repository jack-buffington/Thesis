function fluxMap = PSR(emitters,renderRegion, pixelsPerMeter)
   % Inverse square renderer
   % Written by Jack Buffington 2017
   
   % Creates a map of expected flux around a set of point emitters.
   % This code doesn't take into account attenuation caused by material
   % between the emitters and rendered locations. 
   
   % emitters is an array in the form [X Y activity]
   %     x and y are in meters.
   %     activity is unitless

   % renderRegion is [width height initialX initialY] 
   %     width and height are in meters
   %     initialX and initialY are in meters
   
   % fluxMap is also unitless but follows the inverse square law so will follow 
   % whatever units are applied to activity.

   
   % Break out the values stored in renderRegion
   xPixels = int32(renderRegion(1) * pixelsPerMeter);
   yPixels = int32(renderRegion(2) * pixelsPerMeter);
   initialX = renderRegion(3);
   initialY = renderRegion(4);
   
   
   % split the emitters array into points and intensities
   intensities = emitters(:,3);
   emitterLocations = emitters(:,1:2);
   

   % precalculate all of the distances needed in a vectorized form to speed things up
   Xs = double(1:xPixels);
   Ys = double(1:yPixels);
   
   Xs = Xs / pixelsPerMeter;
   Ys = Ys / pixelsPerMeter;
   
   Xs = Xs + initialX;
   Ys = Ys + initialY;
   
   [xGrid, yGrid] = meshgrid(Xs,Ys);
   Xs = reshape(xGrid,xPixels*yPixels,1);
   Ys = reshape(yGrid,xPixels*yPixels,1);
   pixelCoordinates = double([Xs Ys]);
   
   
   % distanceMatrix contains a matrix of distances between the various points
   % Each row corresponds to an emitter
   % Each column corresponds to a pixel location
   distanceMatrix = pdist2(emitterLocations, pixelCoordinates);  
   
   % Now convert this to into 1/(4*pi*distance^2) and get rid of distances that are zero
   distanceMatrix(distanceMatrix == 0) = .01;
   
   distanceMatrix = distanceMatrix .^2;
   distanceMatrix = distanceMatrix * 4 * pi;
   distanceMatrix = 1 ./ distanceMatrix;

   pixelValues = intensities' * distanceMatrix;
   
   fluxMap = reshape(pixelValues,xPixels,yPixels);
end

