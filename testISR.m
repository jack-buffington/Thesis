function testISR()
   % testISR.m

   % This file operates as follows:
   % To avoid packaging this code with large image files, I have made it so that it
   % renders a dense flux map to 'take measurements' from.
   % It does this first.
   % It comes up with a set of locations where the flux will be measured.
   % Next it 'takes the measurements'.
   % It then passes these measurements to the inverse square renderer.
   % To finish up, it draws a comparison of the results.

   % Note that the estimated map has a red border around it.  These areas are where
   % no estimate has been made and the flux is zero.


   % Make a set of emitters that all have an activity of one.
   [X, Y] = meshgrid((2:.5:4),(6:.5:7));
   X = reshape(X,numel(X),1);
   Y = reshape(Y,numel(Y),1);
   emitters = [X Y ones(size(X,1))]; 
   
   renderRegion = [10 10 0 0];
   
   % Render a dense flux map from these emitters
   pixelsPerMeter = 50;
   actualFluxMap = PSR(emitters,renderRegion, pixelsPerMeter);
   
   % Figure out where to 'take measurements'
   rows = 8;
   cols = 9;
   width = 10 * pixelsPerMeter;
   height = 10 * pixelsPerMeter;
   [X, Y, tri] = makeMeasurementGridAndTriangles(rows,cols, width, height);
   
   
   % 'Measure' the flux at the measurement locations
   fluxMeasurements = zeros(size(X,1),1);
   for I = 1:size(fluxMeasurements,1)
      fluxMeasurements(I,1) = actualFluxMap(Y(I,1),X(I,1));
   end
   
   % convert X & Y back into meters instead of pixels
   X = X / pixelsPerMeter;
   Y = Y / pixelsPerMeter;
   
   % pass everything to the inverse square renderer to let it do its thing.
   estimatedFluxMap = ISR(X, Y, tri, fluxMeasurements, renderRegion, pixelsPerMeter);
   
   
   % Display the results
   colors = makeLookupTable();
   
   figure(1)
   
   subplot(1,2,1)
   fluxMap = sqrt(1./actualFluxMap);
   maxVal = max(max(fluxMap));
   fluxMap = fluxMap / maxVal; % get the map to the range of 0->1
   fluxMap = fluxMap * 255; % then into the 0->255 range that it needs to display 
   imshow(fluxMap,colors)
   title('Actual flux map');
   
   s = subplot(1,2,2);
   fluxMap = sqrt(1./estimatedFluxMap);
   fluxMap = fluxMap / maxVal;  % I am dividing by the same value as the other map
                                % so that the colors are the same for the same flux
                                % values
   fluxMap(fluxMap > 1) = 1;
   fluxMap = fluxMap * 255;
   imshow(fluxMap,colors)
   %imshow(fluxMap);

   title('Estimated flux map');

end





function [X, Y, tri] = makeMeasurementGridAndTriangles(rows,cols, width, height)
   % This function creates a grid of measurement locations and returns the locations 
   % and a triangulation of them.  
   % The locations returned represent measurement locations and have some positional
   % jitter in them.

   % Rows/cols describe the grid of sample points
   % width/height describe the pixel array that the points will be sampled from.
   % X,Y,width,& height are all in pixels.
  
   
   
   jitterSize = 7;
   
   % set up some intial variables
   numPoints = rows*cols;
   xSpacing = floor((width - jitterSize- 1)/(cols-1));
   ySpacing = floor((height - jitterSize - 1)/(rows-1)); 

   X = zeros(numPoints,1);
   Y = zeros(numPoints,1);

   yPos = 0;
   index = 1;
   for I = 1:rows
      xPos = 0;
      for J = 1:cols
         X(index,1) = xPos + 1;
         Y(index,1) = yPos + 1;
         xPos = xPos + xSpacing;
         index = index+1;
      end
      yPos = yPos + ySpacing;
   end 

   if jitterSize ~= 0
      X = X + randi(jitterSize,size(X,1),1);
      Y = Y + randi(jitterSize,size(Y,1),1); 
   end

   % at this point it can do a triangulation but the issue is that you get 
   % thin sliver triangles at the edges so I'm putting in some extra points
   % to force the edge points to connect to it instead

   % Note that this strategy isn't perfect and that you may want to find another
   % method to detect edge triangles.   A likely method would be to check the areas
   % of all triangles and get rid of ones that fall below some threshold.

   X = [X; -width*.1; width*1.1; width/2; width/2];
   Y = [Y; height/2; height/2; -height*.1; height*1.1];

   tri = delaunay(X,Y);  % This returns the index of the points for each triangle

   
   % Now remove the extra points and the triangles that contain them.  
   badTris = tri == size(X,1);
   badTris1 = sum(badTris')';
   badTris = tri == size(X,1)-1;
   badTris2 = sum(badTris')';
   badTris = tri == size(X,1)-2;
   badTris3 = sum(badTris')';
   badTris = tri == size(X,1)-3;
   badTris4 = sum(badTris')';
   
   allBadTris = badTris1 + badTris2 + badTris3 + badTris4 > 0;
   tri = tri(~allBadTris,:);


   X = X(1:size(X,1)-4);
   Y = Y(1:size(Y,1)-4);

end

function theColors = makeLookupTable()
   % make a color lookup table
   
   % this is a simple color gradient starting at red and ending in violet
   theColors = zeros(256,3);
   
   for I = 1:52
      theColors(I,:) = [1 I/52 0];
   end
   
   for I = 1:51
      theColors(I+52,:) = [1 - I/51 1 0];
   end
   
   for I = 1:51
      theColors(I+103,:) = [0 1 I/51];
   end
   
   for I = 1:51
      theColors(I+154,:) = [0 1 - I/51 1];
   end
   
   for I = 1:51
      theColors(I+205,:) = [I/51 0 1];
   end
   
end

function fluxMap = PSR(emitters,renderRegion, pixelsPerMeter)
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