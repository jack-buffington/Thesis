function fluxes = ISR_specificLocations(emitters,locations)
   % Inverse square renderer for specific locations
   % Written by Jack Buffington 2018
   
   % This function returns the expected flux around a set of point emitters at 
   % the specified locations.
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
   
   
   % remove any emitters that have zero activity to speed up render times
   emitters = emitters(emitters(:,3) > 0,:);
   
  
   % each row of distanceMatrix corresponds to an emitter
   % each column of distanceMatrix corresponds to a sample location
   distanceMatrix = pdist2(emitters(:,1:2),locations);
   
   
   % Now convert this to into 1/4*pi*distance^2 and get rid of distances that are zero
   distanceMatrix(distanceMatrix == 0) = .01;
   
   distanceMatrix = distanceMatrix .^2;
   distanceMatrix = distanceMatrix * 4 * pi;
   distanceMatrix = 1 ./ distanceMatrix;
   
   activities = emitters(:,3);
   
   fluxes = (activities' * distanceMatrix)';
end

