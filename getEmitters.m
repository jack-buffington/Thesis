function emitters = getEmitters(mapRegion, emitterSpacing, inputEmitters, exclusionRadius)
               
% This code assumes that exclusion radius is at least sqrt(2) * (measurementSpacing + measurementJitter).
 
% Given a flux map with a given pixels per meter for that map, this function returns
% a set of measurements taken from the measurement region.  Measurements will not be
% returned for areas within exclusionRadius meters of any emitter.  Triangles will
% not be returned which have a vertex within exclusionRadius meters of any emitter.

% mapRegion is [width height initialX initialY] 
%     width and height are in meters
%     initialX and initialY are in meters

% measurementRegion is [width height initialX initialY] 
%     width and height are in meters
%     initialX and initialY are in meters

% fluxMap is an array that is width*pixelsPerMeter x height*pixelsPerMeter

% measurementSpacing is in meters

% emitters are [X Y activity]  In this case, only X & Y will be used as these are
% only for determining where to not take measurements.
% If you don't want to exclude any regions then just make emitters be []

% exclusionRadius is in meters and represents how close to an emitter a
% measurement can be before it is removed from the output.

% measurements are in the form of [X Y measuredFlux]

% measurementJitter is in meters.


% Measurements will initially be made in a grid that fills the entire flux map then
% locations will be removed based on the measurement region and where emitters are
% located.

   % Figure out how many emitter locations there should be along the width and
   % height
   mapWidth = mapRegion(1);
   mapHeight = mapRegion(2);

   % Calculate the emitter locations
   Xlocs = 0:emitterSpacing:mapWidth;
   Ylocs = 0:emitterSpacing:mapHeight;

   % Center the emitters within the width
   Xoffset = (mapWidth - Xlocs(end))/2;
   Yoffset = (mapHeight - Ylocs(end))/2;
   Xlocs = Xlocs + Xoffset;
   Ylocs = Ylocs + Yoffset;

   % Adjust the emitters to be where they really are supposed to be
   Xlocs = Xlocs + mapRegion(3);
   Ylocs = Ylocs + mapRegion(4);

   % Now turn these locations into a set of coordinates
   [X,Y] = meshgrid(Xlocs,Ylocs);
   X = reshape(X,numel(X),1);
   Y = reshape(Y,numel(Y),1);
   emitters = [X Y];  %this isn't the final form.  It will have a third collumn with the flux values


   % Flag any emitter locations that are within exclusionRadius of any emitters   
   if size(inputEmitters,1) > 0
      distances = pdist2(emitters,inputEmitters(:,1:2));   % results in a row for every measurement
                                                           % and a collumn for every emitter
      badDistances = distances < exclusionRadius;
      goodEmitters = sum(badDistances,2) ~= 0;
   end


   % Remove any emitter locations that are flagged.
   emitters = emitters(goodEmitters == 1,:);
   
   % Give all of the emitters an initial value of 0
   emitters = [emitters zeros(size(emitters,1),1)];
end




