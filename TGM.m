function estimates = TGM(measurements, triangles)
% Pass this function a set of measurements and their triangluation
% Returns a set of estimated source locations
% findEmitterActivityAndLocation also returns estimated emitter activities. 
% I didn't feel that this would be useful so I didn't do anything with it but 
% it was easy to implement...
% 

% measurements is [X, Y, flux]
% estimates is in the form [X, Y]


   X = measurements(:,1);
   Y = measurements(:,2);
   fluxes = measurements(:,3);
   estimates = [];

   % Indicate the estimated point source location for each triangle
   for I = 1:size(triangles,1) 
      XX = [X(triangles(I,1)) X(triangles(I,2)) X(triangles(I,3))];
      YY = [Y(triangles(I,1)) Y(triangles(I,2)) Y(triangles(I,3))];
      value = [fluxes(triangles(I,1)) fluxes(triangles(I,2)) fluxes(triangles(I,3))];


      % find the center of the triangle
      centerX = mean(XX);
      centerY = mean(YY);


      angle2 = findGradientDirection03(value',[XX',YY']);
      angle = wrapToPi(angle2);



      % find the intersections with the edges of the triangle.  
      point = [centerX centerY];  

      lineSegment1 = [XX(1) YY(1); XX(2) YY(2)];

      IP1 = findIntersection(point, angle, lineSegment1);
      lineSegment1 = [lineSegment1  [value(1); value(2)]];


      lineSegment2 = [XX(2) YY(2); XX(3) YY(3)];
      IP2 = findIntersection(point, angle, lineSegment2);
      lineSegment2 = [lineSegment2  [value(2); value(3)]];


      lineSegment3 = [XX(1) YY(1); XX(3) YY(3)];
      IP3 = findIntersection(point, angle, lineSegment3);
      lineSegment3 = [lineSegment3  [value(1); value(3)]];


      % Figure out which two sides to use.  
      if isempty(IP1)
         segment1 = lineSegment2;
         segment2 = lineSegment3;
         intersection1 = IP2;
         intersection2 = IP3;
      else
         segment1 = lineSegment1;
         intersection1 = IP1;
         if isempty(IP2)
            segment2 = lineSegment3;
            intersection2 = IP3;
         else
            segment2 = lineSegment2;
            intersection2 = IP2;
         end
      end



      % segment1 and segment2 are organized as two rows of [X Y flux]

      % Now it has figured out which segments it intersects and where the
      % intersections are.  This is stored in segment1, segement2, IP1, and
      % IP2.

      % Find the flux at the intersection point
      point1 = segment1(1,1:2);
      point2 = segment1(2,1:2);
      testPoint = intersection1;
      flux1 = segment1(1,3);
      flux2 = segment1(2,3);

      intersectionFlux1 = findFlux(point1, point2, testPoint, flux1, flux2);

      point1 = segment2(1,1:2);
      point2 = segment2(2,1:2);
      testPoint = intersection2;


      flux1 = segment2(1,3);
      flux2 = segment2(2,3);
      intersectionFlux2 = findFlux(point1, point2, testPoint, flux1, flux2);


      [location, activity] = findEmitterActivityAndLocation(intersection1, intersectionFlux1, intersection2, intersectionFlux2);
      estimates = [estimates;location];
   end
end



% ############################
% ##### Helper functions #####
% ############################

function currentDirection = findGradientDirection03(fluxes, vertices)
   % Iteratively finds the gradient direction using the method that is used to render
   % the triangles.   
   % It starts its search by looking in the direction perpendicular to the segment
   % that runs between the min and max.  It then steps in initialStepSize increments 
   % until it see that the direction of the error changed, at which point it reverses
   % direction and cuts the step size in half.  When the step size is below a
   % threshold, it stops searching and returns an unit normal.  
   
   
   % KNOWN ISSUES:
   % If two sides have the same amount of difference in flux then this will give a
   % bad result.   It doesn't seem to come up in practice but I have a stub of code
   % at the bottom of this file to address it should it start to happen in practice. 
   
   initialStepSize = pi/4;  
   finalStepSize =.002;
   
   % Find the direction from max to min vertex.
   [~, so] = sort(fluxes);  % so: sort order
   temp = vertices(so(3),:) - vertices(so(1),:);
   
   minMaxDirection = atan2(temp(2),temp(1));   %This is in radians   % #### may not be negative
   
   % Find the flux for the middle vertex
   middleFlux = fluxes(so(2));
   
   % Find the direction perpendicular to it.  
   currentDirection = minMaxDirection - pi/2;  

   % Find the flux at the perpendicular.
   normal = [cos(currentDirection) sin(currentDirection)]; % this is in the direction of the current direction
   flux = findFluxAtMidValueVertex(normal, vertices, fluxes);
   lastError = middleFlux - flux;
   stepAngle = -initialStepSize;

count = 0;   

   while (abs(stepAngle)) > finalStepSize 
      % adjust the current direction based on the direction of the error
      currentDirection = currentDirection + stepAngle;
      

      % find the flux given the current direction
      normal = [cos(currentDirection) sin(currentDirection)];
      flux = findFluxAtMidValueVertex(normal, vertices, fluxes);
      
      % if the direction of the error is different from last time then multiply the
      % step angle by -.5
      thisError = middleFlux - flux;
      
      if sign(thisError) ~= sign(lastError)
         stepAngle = stepAngle * (-.5);
      end
      
      lastError = thisError;
      count = count + 1;
   end




   if count > 30
      disp('count went haywire in findGradientDirection03...');
      disp(count);
      % It does this when the flux difference on two legs is the same.
      % Correct this by returning a direction 90 degrees from the line that passes 
      % through the two points that have the same flux and ###### in the direction that
      % is closest to high to low flux.  
      
      % Find the side with the same flux at both ends.  
      
      % Find the angle that is 90 degrees from that side and which points in the 
      % direction of increasing flux.  
   end

end

function flux = findFluxAtMidValueVertex(normal, vertices, fluxes)  
% Calculates the flux at the middle vertex given the provided info.  Used for
% finding the gradient direction.
      
   [minProjectedValue, projectedRange] = findMinMaxCoordinates(vertices, normal); 
   [scaledXvalue, maxFlux] = findScaledXvalue(fluxes); 
   
   % Figure out which vertex has the middle amount of flux
   [~,sortOrder] = sort(fluxes);
   middleVertex = sortOrder(2);
   
   scaledXvalue = scaledXvalue - 1; % this is now the range from 1 to scaledXvalue
   
   X = vertices(middleVertex,1);
   Y = vertices(middleVertex,2);
   
   % Project the vertex onto the normal.
   projectedCoordinate = [X Y] * normal';
   projectedCoordinate = projectedCoordinate - minProjectedValue;
   percentAlong = projectedCoordinate / projectedRange; 
   Xvalue = scaledXvalue * percentAlong + 1;
   Yvalue = 1/(Xvalue^2); 
   flux = maxFlux * Yvalue;
end



function [minCoordinate, range] = findMinMaxCoordinates(vertices, normal)
% Projects the vertices onto the normal and finds the minimum coordinate and the
% range of the projected coordinates
   projectedCoordinates = vertices * normal';
   minCoordinate = min(projectedCoordinates);
   range = max(projectedCoordinates) - minCoordinate;
end


function [scaledXvalue, maxFlux] = findScaledXvalue(fluxes)
% Finds the X value that corresponds to the minimum flux
   sortedFluxes = sort(fluxes);
   minFlux = sortedFluxes(1);
   maxFlux = sortedFluxes(3);
   
   percentRemaining = minFlux/maxFlux;
   scaledXvalue = sqrt(1/percentRemaining);
end


function intersectionPoint = findIntersection(point, angle, lineSegment)
   % Checks to see if there is an intersection between the line given as
   % point/angle and the line segment within the bounds of the line segment
   % Returns [X,Y] if it does and [] if it doesn't.
   % point is in the form [X,Y]
   % lineSegment is in the form [X,Y]  
   %                            [X,Y]

   x01 = point(1);
   y01 = point(2);
   m1 = tan(angle);
   
   x02 = lineSegment(1,1);
   y02 = lineSegment(1,2);
   m2 = (lineSegment(2,2) - lineSegment(1,2)) / (lineSegment(2,1) - lineSegment(1,1)); 
   
   
   % Prevent errors in the next calculation
   if m1 == inf
      m1 = 99999999;
   elseif m1 == -inf
      m1 = -99999999;
   end
   
   if m2 == inf
      m2 = 99999999;
   elseif m2 == -inf
      m2 = -99999999;
   end
   
   
   if (m1-m2) == 0
      intersectionPoint = [];
   else
      X = (y02 - m2 * x02 - y01 + m1 * x01)/(m1 - m2);
      Y = m1 * X - m1 * x01 + y01;

      % Check to see if this is within bounds.  
      % Return [] if it doesn't.

      % Figure out which dimension of the line segment is longer and check
      % against that one.  This will prevent issues with numerical precision.


      span = range(lineSegment);
      if span(1) > span(2)  % if the segment is longer in X than Y
         if X >= min(lineSegment(:,1)) && X <= max(lineSegment(:,1))
            intersectionPoint = [X Y];
         else
            intersectionPoint = [];
         end
      else  % if the segment is longer in Y than X
         if Y >= min(lineSegment(:,2)) && Y <= max(lineSegment(:,2))
            intersectionPoint = [X Y];
         else
            intersectionPoint = [];
         end
      end
   end
end


function flux = findFlux(point1, point2, testPoint, flux1, flux2)
   % given two points in the form (X,Y) and their corresponding fluxes,
   % return the flux at the test point

   isFlipped = false;
   if flux2 > flux1
      isFlipped = true;
   end

   totalDistance = pdist([point1;point2]);
   
   if isFlipped == true % point2 has greater flux
      % this prevents an error where it returns nan for all values
      if flux2 == 0
         flux2 = .000001;
      end
      
      percentRemaining = flux1 / flux2; % when compared to original value
      endPoint = sqrt(1/percentRemaining);
      
      testDistance = pdist([point2;testPoint]);                                     
      X = (endPoint - 1) * (testDistance/totalDistance) + 1; % this is a point between 1 and endPoint
      
      % find the flux at X
      flux = flux2/(X^2);

     
   else % point1 has greater flux.
      % this prevents an error where it returns nan for all values
      if flux1 == 0
         flux1 = .000001;
      end
   
      percentRemaining = flux2 / flux1; % when compared to original value
      endPoint = sqrt(1/percentRemaining); % this is the value on the inverse square graph that has
                                           % the same percent remaining as
                                           % the flux that we are comparing
                                           % to.
      
      testDistance = pdist([point1;testPoint]);                                     
      X = (endPoint - 1) * (testDistance/totalDistance) + 1; % this is a point between 1 and endPoint
      
      % find the flux at X   
      flux = flux1/(X^2);
   end
end

function [position, activity] = findEmitterActivityAndLocation(point1, flux1, point2, flux2)
   % Given two points with coordinates(X,Y), finds the location of the
   % emitter and how strong it is.
   % ##############################################################################
   % THIS FUNCTION IS ASSUMING THAT PIXELSPERMETER IS 30 ...MAY BE OK IF I USE THIS
   % VALUE ELSEWHERE
   % ##############################################################################
   
   pixelsPerMeter = 30;
   distanceBetweenPoints = pdist([point1;point2]);
   
   % swap the points if flux2 is greater than flux1
   if flux2 > flux1
      temp = flux2;
      flux2 = flux1;
      flux1 = temp;
      
      temp = point2;
      point2 = point1;
      point1 = temp;
   end
   
   
   changeInPosition = point2 - point1;
   
   
   % At this point, point1 will have stronger flux.
   
   % Find the point on the inverse square graph that corresponds to the
   % lower flux.  
   percentRemaining = flux2/flux1;
   
   X = sqrt(1/percentRemaining);  % this is the point on the graph that 
                                  % matches the point with lower flux

   distanceToEmitter = (X-1)/distanceBetweenPoints; 
   distanceToEmitter = distanceToEmitter / pixelsPerMeter;
   activity = flux1 * 12.56636 * distanceToEmitter^2;
   position = point1 - changeInPosition/(X - 1);
end


 