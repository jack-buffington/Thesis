function testPSR()
   % testPSR.m
   % Written by Jack Buffington 2018

   % Make a color lookup table to display the flux
   colors = makeLookupTable();

   % emitters is an array in the form [X Y activity]
   %     x and y are in meters.
   %     activity is unitless
   emitters = [2 2 10; 5 7 3];

   pixelsPerMeter = 50;


   % renderRegion is [width height initialX initialY] 
   %     width and height are in meters
   %     initialX and initialY are in meters
   renderRegion = [10 10 0 0];  

   fluxMap = PSR(emitters,renderRegion, pixelsPerMeter);

   fluxMap = sqrt(1./fluxMap);
   fluxMap = fluxMap / max(max(fluxMap)); % get the map to the range of 0->1
   fluxMap = fluxMap * 255;
   
   imshow(fluxMap,colors)
   title('Estimated flux map');

   
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