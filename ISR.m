function fluxMap = ISR(X, Y, tri,fluxMeasurements, renderRegion, pixelsPerMeter)
% X & Y are in meters
% fluxMeasurements are unitless but relate to the units used for emitters. 
% renderRegion is [width height initialX initialY]  All in meters
% pixelsPerMeter is self explanatory

   startCoordinate = [renderRegion(3) renderRegion(4)];
   mapDimensions = [renderRegion(1) renderRegion(2)];

   fluxMap = zeros(int32(mapDimensions(2)*pixelsPerMeter), ...
                  int32(mapDimensions(1)*pixelsPerMeter));

   % render each triangle separately
   for I = 1:size(tri,1)
      vertices = [X(tri(I,1)) Y(tri(I,1)); ...
                  X(tri(I,2)) Y(tri(I,2)); ...
                  X(tri(I,3)) Y(tri(I,3))];
      fluxes = [fluxMeasurements(tri(I,1)); ...
                fluxMeasurements(tri(I,2)); ...
                fluxMeasurements(tri(I,3))];
                
      fluxMap = renderCompleteTriangle(fluxes,vertices, fluxMap, startCoordinate,...
                                pixelsPerMeter);
   end
end 



% Helper functions are below
% |  |  |  |  |  |  |  |  |
% V  V  V  V  V  V  V  V  V



function pixels = renderCompleteTriangle(fluxes,vertices, pixels, startCoordinate,...
                                         pixelsPerMeter)
% Renders a triangle into the pixels array.
% * Finds the gradient direction (normal)
% * Finds the min and range of coordinates of the vertices projected onto the normal
% * Splits the triangle into two where one has a flat top and the other has a flat 
%   bottom 
% * Calculates the scaled X value that is used for inverse square interpolation
% * Renders the top triangle
% * Renders the bottom triangle

   normal = findGradientDirection03(fluxes, vertices); 
   [minProjectedValue, projectedRange] = findMinMaxCoordinates(vertices, normal); 
   triangles = splitTriangle(vertices); 
   [scaledXvalue, maxFlux] = findScaledXvalue(fluxes); 
   
   % Render the first triangle
   pixels = renderHalfTriangle02(normal, minProjectedValue,...
         projectedRange, triangles(1:3,:), pixels, startCoordinate, pixelsPerMeter,...
         maxFlux, scaledXvalue);
      
   % If there are two triangles then render the second triangle
   if size(triangles,1) == 6
      pixels = renderHalfTriangle02(normal, minProjectedValue,...
         projectedRange, triangles(4:6,:), pixels, startCoordinate, pixelsPerMeter,...
         maxFlux, scaledXvalue);
   end
end



function pixels = renderHalfTriangle02(gradientDirection, minProjectedValue,...
         projectedRange, vertices, pixels, startCoordinate, pixelsPerMeter,...
         maxFlux, scaledXvalue)
% Renders a triangle that has either a flat top or a flat bottom into the pixels 
% array.   
% gradientDirection is a unit vector in the form [X Y]
% minProjectedValue is the minimum value found when projecting the original
%      triangle's vertices onto the gradient vector.
% projectedRange is max-min of the projected values from the original triangle
% vertices are in the form [X Y]  and are in meters
%                          [X Y]
%                          [X Y]
% Start coordinate is in the from [X Y] in meters and represents the start coordinate
%     of the render window.
% maxFlux is the maximum flux for the original triangle's vertices.
% scaledXvalue is the X value that corresponds with the minimum amount of flux seen
% in the original triangle's vertices.
      
   scaledXvalue = scaledXvalue - 1; % this is now the range from 1 to scaledXvalue

   % Convert things to pixel coordinates
   startCoordinateInPixels = startCoordinate * pixelsPerMeter;
   endCoordinateInPixels = startCoordinateInPixels + fliplr(size(pixels));    
   
   verticesInPixels = int32(vertices * pixelsPerMeter);
   
   
   maxYpixel = max(verticesInPixels(:,2));
   minYpixel = min(verticesInPixels(:,2));
   maxXpixel = max(verticesInPixels(:,1));
   minXpixel = min(verticesInPixels(:,1));
   
   drawTriangle = true;
   if (maxYpixel > endCoordinateInPixels(2) && ...
       minYpixel > endCoordinateInPixels(2)) || ...
       (maxYpixel < startCoordinateInPixels(2) && ...
       minYpixel < startCoordinateInPixels(2))
      % then all Y coordinates are outside of the render window
      drawTriangle = false;
   end
   
   if (maxXpixel > endCoordinateInPixels(1) && ...
       minXpixel > endCoordinateInPixels(1)) || ...
       (maxXpixel < startCoordinateInPixels(1) && ...
       minXpixel < startCoordinateInPixels(1))
      % then all X coordinates are outside of the render window
      drawTriangle = false;
   end
   
   
   


   % Start rendering the pixels into the pixels array.  For each row, check to see if
   % it is within the drawable area and then within each row, check each pixel to see
   % if it is within the drawable area.  
   % After rendering each pixel, subtract the offset before assigning it to the
   % pixels array.
   
   if drawTriangle == true
      % limit things to the drawable range
      maxYpixel = min([maxYpixel endCoordinateInPixels(2)]); 
      maxYpixel = max([maxYpixel startCoordinateInPixels(2)]);
      
      minYpixel = min([minYpixel endCoordinateInPixels(2)]);
      minYpixel = max([minYpixel startCoordinateInPixels(2)]);
      
      
      
      % Find the slopes for the sides
      temp = verticesInPixels(3,:) - verticesInPixels(1,:);
      slope1 = double(temp(2));
      slope1 = slope1/double(temp(1));
      temp = verticesInPixels(3,:) - verticesInPixels(2,:);
      slope2 = double(temp(2));
      slope2 = slope2 /double(temp(1));

      if abs(slope1) == inf   % correct a bug where it wants to render from 0 for a
         slope1 = sign(slope1) * 1000;  % a scan line
      end
      
      if abs(slope2) == inf
         slope2 = sign(slope2) * 1000;
      end
      

      % The triangles are in the form
      %
      %       1---2                   3
      % slope1 \ / slope2     slope1 / \ slope2
      %         3                   1---2

      
      for Y = minYpixel:maxYpixel
         % Calculate the X start and stop points    
         startX = int32( (Y - verticesInPixels(3,2))/slope1 + ...
                  verticesInPixels(3,1));
         endX = int32( (Y - verticesInPixels(3,2))/slope2 + ...
                verticesInPixels(3,1));      
               
         
         % Limit things to the drawable area
         Xchanges = 0;
         if startX > endCoordinateInPixels(1)
            startX = endCoordinateInPixels(1);
            Xchanges = 1;
         elseif startX < startCoordinateInPixels(1)
            startX = startCoordinateInPixels(1);
            Xchanges = 1;
         end
         
         if endX > endCoordinateInPixels(1)
            endX = endCoordinateInPixels(1);
            Xchanges = Xchanges + 1;
         elseif endX < startCoordinateInPixels(1)
            endX = startCoordinateInPixels(1);
            Xchanges = Xchanges + 1;
         end
         
         
         

         if Xchanges ~= 2 % then it wasn't completely off screen so draw it.  
         
            for X = startX:endX
               % Render the pixel then shift and store its value into the pixels array

               % Project the pixel onto the normal.
               projectedCoordinate = [double(X)/pixelsPerMeter double(Y) /  ...
                                      pixelsPerMeter] * gradientDirection';
               projectedCoordinate = projectedCoordinate - minProjectedValue;
               percentAlong = projectedCoordinate / projectedRange; 
               Xvalue = scaledXvalue * percentAlong + 1;
               Yvalue = 1/(Xvalue^2); 
               pixelValue = maxFlux * Yvalue;

               tempX = X-startCoordinateInPixels(1);
               tempY = Y-startCoordinateInPixels(2);

               if tempX ~= 0 && tempY ~= 0
                  pixels(tempY,tempX) = pixelValue;
               end
            end
         end % of if Xchanges ~= 2
      end % of going through the Y coordinates
   end % of if it should draw anything at all 
end




function triangles = splitTriangle(vertices)
% Splits a triangle into one or two triangles.  It will generate two triangles if the
% given triangle has no horizontal sides otherwise it will generate one.   The
% triangles will be stored in a 2D matrix where the first triangle is in the first
% three rows and if there is a second triangle, it will be in rows 4-6.
% The triangles will be organized so that the points are in the form:
%
% 1---2     3
%  \ /     / \
%   3     1---2
%
% Where the number is the row that has the information for that vertex


   sortedVertices = sortrows(vertices,2); % Sorts by the last column (Y) low to high
   
   bottomVertices = sortedVertices;
   topVertices = sortedVertices;
   
   % Calculate the third vertex for both triangles.
   temp = sortedVertices(1,:) - sortedVertices(3,:);
   slope = temp(2)/temp(1); % slope of the side that spans the largest change in Y

   % I'm using the formula y-y0 = m(x-x0) to solve for the third point.
   Y0 = bottomVertices(1,2);
   X0 = bottomVertices(1,1);
   
   Y = bottomVertices(2,2);
   
   if slope == inf || slope == -inf  % fix a render bug if the slope is infinite
      X = X0;
   else
      X = (Y - Y0 + slope * X0)/slope;
   end
   
   bottomVertices(3,1) = X;
   bottomVertices(3,2) = Y;
   
   topVertices(1,1) = X;
   topVertices(1,2) = Y;   % looks good to here

   
   % Get the triangles into the form shown above
   % They are currently in the form
   %
   % 3---2     3
   %  \ /     / \
   %   1     1---2
   
   % I want them in the form:
   %
   % 1---2     3
   %  \ /     / \
   %   3     1---2
   %
   temp = bottomVertices(3,:);
   bottomVertices(3,:) = bottomVertices(1,:);
   bottomVertices(1,:) = temp;
   

   if bottomVertices(1,1) > bottomVertices(2,1)
      temp = bottomVertices(2,:);
      bottomVertices(2,:) = bottomVertices(1,:);
      bottomVertices(1,:) = temp;
   end
   
   if topVertices(1,1) > topVertices(2,1)
      temp = topVertices(2,:);
      topVertices(2,:) = topVertices(1,:);
      topVertices(1,:) = temp;
   end
   
   % At this point, the points in the triangles should be sorted so that the vertex 
   % with the lowest X coordinate for the horizontal side is in position 1 and the 
   % other horizontal side vertex should be in position 2.
   
   
   % Now determine what to put into the triangles array.  If the triangle aready had
   % a flat top or bottom then it will have been squashed flat by the procedure above
   triangles = [];
   if ~(topVertices(1,1) == topVertices(2,1) && topVertices(1,1) == topVertices(3,1))
      % Then put the top triangle in the triangles array
      triangles = topVertices;
   end

   % Don't add all of the second triangle's vertices if they are colinear
   if ~((bottomVertices(1,1) == bottomVertices(2,1) && ...
        bottomVertices(1,1) == bottomVertices(3,1)) || ...
        (bottomVertices(1,2) == bottomVertices(2,2) && ...
        bottomVertices(1,2) == bottomVertices(3,2)))
      % Then put the bottom triangle in the triangles array
      triangles = [triangles;bottomVertices];
   end
end





function [scaledXvalue, maxFlux] = findScaledXvalue(fluxes)
% Finds the X value that corresponds to the minimum flux
   sortedFluxes = sort(fluxes);
   
   minFlux = sortedFluxes(1);
   maxFlux = sortedFluxes(3);
   
   percentRemaining = minFlux/maxFlux;
   scaledXvalue = sqrt(1/percentRemaining);
end





function [minCoordinate, range] = findMinMaxCoordinates(vertices, normal)
% Projects the vertices onto the normal and finds the minimum coordinate and the
% range of the projected coordinates
   projectedCoordinates = vertices * normal';
   minCoordinate = min(projectedCoordinates);
   range = max(projectedCoordinates) - minCoordinate;
end




function normal = findGradientDirection03(fluxes, vertices)
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
   currentDirection = minMaxDirection - pi/2;  % ###########  this may need to be subtracted
                                               % seems to find same solution
                                               % regardless of which way I do it.

   
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






function flux = findFluxAtMidValueVertex(normal, vertices, fluxes) %, pixelsPerMeter)
      
% Calculates the flux at the middle vertex given the provided info.  Used for
% finding the gradient direction.



% gradientDirection is a unit vector in the form [X Y]
% minProjectedValue is the minimum value found when projecting the original
%      triangle's vertices onto the gradient vector.
% projectedRange is max-min of the projected values from the original triangle
% vertices are in the form [X Y]  and are in meters
%                          [X Y]
%                          [X Y]
% Start coordinate is in the from [X Y] in meters and represents the start coordinate
%     of the render window.
% maxFlux is the maximum flux for the original triangle's vertices.
% scaledXvalue is the X value that corresponds with the minimum amount of flux seen
% in the original triangle's vertices.
      
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
