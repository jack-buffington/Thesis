function [measurements, triangles] = getMeasurements(fluxMap, mapRegion, measurementRegion, ...
    pixelsPerMeter, measurementSpacing, measurementJitter, emitters, exclusionRadius)
               
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

   % Figure out how many measurement locations there should be along the width and
   % height
   mapWidth = mapRegion(1);
   mapHeight = mapRegion(2);

   % Calculate the measurement locations
   Xlocs = 0:measurementSpacing:mapWidth;
   Ylocs = 0:measurementSpacing:mapHeight;

   % Center the measurements within the width
   Xoffset = (mapWidth - Xlocs(end))/2;
   Yoffset = (mapHeight - Ylocs(end))/2;
   Xlocs = Xlocs + Xoffset;
   Ylocs = Ylocs + Yoffset;

   % Adjust the measurements to be where they really are supposed to be
   Xlocs = Xlocs + mapRegion(3);
   Ylocs = Ylocs + mapRegion(4);

   % Now turn these locations into a set of coordinates
   [X,Y] = meshgrid(Xlocs,Ylocs);
   X = reshape(X,numel(X),1);
   Y = reshape(Y,numel(Y),1);
   measurements = [X Y];  %this isn't the final form.  It will have a third collumn with the flux values



   % Apply the jitter
   jitter = rand(size(measurements)) * measurementJitter;
   measurements = measurements + jitter;


   % In preparation for triangulation, place some extra measurement locations around the 
   % mapRegion that will prevent sliver triangles from showing up. Additionally, create
   % a useThisMeasurement array.  Flag these new locations in that array.


   %row below
   Y = mapRegion(4) - measurementSpacing;
   measurements = [measurements; [Xlocs' repmat(Y,[size(Xlocs'),1])]];

   % row above
   Y = mapRegion(4) + mapRegion(2) + measurementSpacing;
   measurements = [measurements; [Xlocs' repmat(Y,[size(Xlocs'),1])]];

   %row to left
   X = mapRegion(3) - measurementSpacing;
   measurements = [measurements; [repmat(X,[size(Ylocs'),1]) Ylocs']];

   % row to right
   X = mapRegion(3) + mapRegion(1) + measurementSpacing;
   measurements = [measurements; [repmat(X,[size(Ylocs'),1]) Ylocs']];

   useThisMeasurement = ones(size(measurements,1),1);



   % Flag any measurement locations that are outside of the measurement region
   % or just too close to the edges

   % Too low of an X
   useThisMeasurement(measurements(:,1) < measurementRegion(3) + 1/pixelsPerMeter) = 0;
   % Too high of an X
   useThisMeasurement(measurements(:,1) > measurementRegion(3) + measurementRegion(1) - 1/pixelsPerMeter ) = 0;
   % Too low of an Y
   useThisMeasurement(measurements(:,2) < measurementRegion(4) + 1/pixelsPerMeter) = 0;
   % Too high of an Y
   useThisMeasurement(measurements(:,2) > measurementRegion(4) + measurementRegion(2) - 1/pixelsPerMeter) = 0;



   % Flag any measurements locations that are within exclusionRadius of any emitters
   if size(emitters,1) > 0
      distances = pdist2(measurements,emitters(:,1:2));   % results in a row for every measurement
                                                          % and a collumn for every emitter
      badDistances = distances < exclusionRadius;
      goodMeasurements = sum(badDistances,2) == 0;
      useThisMeasurement = useThisMeasurement .* goodMeasurements;
   end

   


   % Triangulate the measurement locations
   tri = delaunay(measurements(:,1), measurements(:,2));


   % Remove any triangles that use flagged locations
   badMeasurements = useThisMeasurement == 0;
   badLocationIndices = find(badMeasurements);
   badTriangles = sum(ismember(tri,badLocationIndices),2);
   triangles = tri(badTriangles == 0,:); 


   
   % Remove any measurement locations that are flagged.
   measurements = [measurements (1:size(measurements,1))']; % Store the indices so that 
                                                          % triangles can be
                                                          % reconnected
   measurements = measurements(useThisMeasurement == 1,:);
   
   % Reconnect the triangles to the proper measurements
   for I = 1:size(measurements,1)
      oldIndex = measurements(I,end);
      triangles(triangles == oldIndex) = I;
   end
   
   % Strip away the extra column from measurements
   measurements = measurements(:,1:end-1);
   
   

   % Make a temporary measurement location array that is in pixel coordinates
   measurementPixels = round(measurements * pixelsPerMeter);


   % sample the flux at the remaining measurement locations.
   fluxValues = zeros(size(measurementPixels,1),1);
   
   for I = 1:size(measurementPixels,1)  % There is probably some way to verctorize this...
      X = measurementPixels(I,1);
      Y = measurementPixels(I,2);
      fluxValues(I) = fluxMap(Y,X);
   end
   
   measurements = [measurements fluxValues];


end












