function [fluxMap, exclusionMap] = renderFluxMapFromImage(file, inputPixelsPerMeter, ...
                                  outputPixelsPerMeter, initialCoordinate, ...
                                  maxStrength, outputRenderRegion)
% Renders a flux map when given an image that indicates the positions and strengths
% of emitters.   
% This function will create an emitter for every pixel that doesn't have a value of 
% zero.  
% file: An image which indicates where emitters are placed 
% pixelsPerMeter: defines the spacing of the emitters.
% initialCoordinates: where the image starts in meters.
% maxStrength: Defines the strength of an emitter placed where a pixel value is 1
% outputRenderRegion:  [width height initialX initialY] 
%     width and height are in meters
%     initialX and initialY are in meters
% exclusionRegion is a map that has 0's where there were non-zero pixels in the input
% image
   smoothColorsBlack = [(1:-1/255:0)' (1:-1/255:0)' (1:-1/255:0)']; 
   image = imread(file);
   

   if size(image,3) == 3
      disp('Image was RGB.   Converting to greyscale.');
      image = rgb2gray(image);
   end
   
   figure(1);
   set(gcf, 'Position', get(0, 'Screensize'));
   subplot(1,3,1)
   imshow(image);
   title('Source map');
   
   % convert the image into emitter strengths
   image = (double(image) / 255)*maxStrength;
   
   % create the emitters
   [row, col] = find(image); % finds all non-zero pixels
   emitters(:,1) = (col / inputPixelsPerMeter) + initialCoordinate(1);
   emitters(:,2) = (row / inputPixelsPerMeter) + initialCoordinate(2);
   for I = 1:size(emitters,1)
      emitters(I,3) = image(row(I),col(I));
   end

   
   % Render a dense map of flux from these emitters.  
   fluxMap = PSR(emitters,outputRenderRegion, outputPixelsPerMeter);

   
   % convert the map into displayable format
   map2 = sqrt(1./fluxMap);
   map2Divider = max(max(map2));
   map2 = map2 / map2Divider; % get the map to the range of 0->1


   subplot(1,3,2)
   map2 = map2 * 256;  % I'm doing this because the colormap command is working
                       % differently when I supply it with imshow.  
   imshow(map2,smoothColorsBlack)
   title('Flux map');
   
   % scale the input image to the size of the output image
   scaleFactor = outputPixelsPerMeter/inputPixelsPerMeter;
   eMap = imresize(image,scaleFactor);
   exclusionMap = eMap == 0;
   
   
   
   
   %expand the exclusion region using the mask below
   % 0011100
   % 0111110
   % 1111111
   % 1111111
   % 1111111
   % 0111110
   % 0011100
   N = zeros(7,7);
   N(3:5,1:7) = 1;
   N(1:7,3:5) = 1;
   N(2,2) = 1;
   N(2,6) = 1;
   N(6,6) = 1;
   N(6,2) = 1;

   SE = strel('arbitrary',N);      % SE is the mask in the form that imerode needs it                    
   exclusionMap = double(exclusionMap);  
   for I = 1:5
      exclusionMap = imerode(exclusionMap,SE); 
   end
   
   subplot(1,3,3)
   imshow(exclusionMap);
   title('Exclusion map');
   
  
end