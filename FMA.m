function emitters = FMA(numberOfIterations, emitters, measurements, renderRegion,...
                  maxAllowablePercentageIncrease, acceptanceFrequency, sigmaConstant)
               
   % numberOfIterations set this to something in the range of 10,000 to 300,000
   %     higher numbers will create emitters that produce a more accurate flux field
   
   % emitters - These are in the form [X Y 0] and represent the locations of the
   %        emitters
   % measurements - These are in the form [X Y measurement] where measurement is a
   %        gamma flux measurement.  For the sake of FMA, this will be in a form
   %        that isn't necessarily counts but uses units that would naturally come
   %        from emitters.
   % renderRegion is in the form [width height, startX, startY] all in meters
   % maxAllowablePercentageIncrease is usually .2 (20%) but I broke it out to allow 
   %        it to be changed.
   % acceptanceFrequency is normally 8.  Much below that and it becomes unstable.
   % sigmaConstant is normally 20.
               
               
   % Set up some initial values
   minScore = Inf;
   bestEmitters = [];
   fluxes = measurements(:,3);
   sampleLocations = measurements(:,1:2);
   maximumRectanglePercentage = .05; % determines the maximum size of the rectangle 
                                     % that can select emitters.
   emitterLocations = emitters(:,1:2);
                   
   previousLowestTotalFlux = sum(measurements(:,3) .^ 2);
   lastFlux = previousLowestTotalFlux;
   strengthSigma = previousLowestTotalFlux / sigmaConstant;

   stillWorking = true;
   iteration = 0;

   fprintf ('Iteration: ');
   charsToErase = 0;
   
   while stillWorking == true
      iteration = iteration + 1;
      if mod(iteration,100) == 0
         % erase any prevous characters
         for I = 1:charsToErase
            fprintf('\b');
         end
         
         % print the new value
         s = sprintf('%d',iteration);
         charsToErase = length(s);
         fprintf('%s',s);
      end


      % Randomly select a rectangle of emitters
      stillSearching = true;
      while stillSearching == true
         % randomly create a rectangle and then check to see if it contains any
         % emitters
         rectangle = rand(1,4);  % I'm going to treat this as 1/2 width, 1/2 height, center X,center Y
         rectangle(1:2) = rectangle(1:2) .* renderRegion(1:2) * maximumRectanglePercentage; 
         rectangle(3:4) = rectangle(3:4) .* renderRegion(1:2) + renderRegion(3:4);

         % Check to see if this rectangle contains any of the emitters
         startX = rectangle(3) - rectangle(1);
         endX = rectangle(3) + rectangle(1);
         startY = rectangle(4) - rectangle(2);
         endY = rectangle(4) + rectangle(2);

         % ContainedEmitters is a vector of 1's and 0's 
         containedEmitters = emitterLocations(:,1) > startX & ...
                             emitterLocations(:,1) < endX & ...
                             emitterLocations(:,2) > startY & ...
                             emitterLocations(:,2) < endY;

         if sum(containedEmitters > 0)
            stillSearching = false;
         end
      end % of still searching



      tempEmitters = emitters;



      % containedEmitters now contains 1's indicating which emitters should be
      % modified.  Modify those emitters
      modAmount = normrnd(0,strengthSigma); % 0 mean sigma of strengthSigma
      tempEmitters(containedEmitters,3) = tempEmitters(containedEmitters,3) + modAmount;




      % Keep the activities positive
      tempEmitters(tempEmitters(:,3) < 0,3) = 0;


      % Evaluate the solution provided by tempEmitters
      evaluationFluxes = renderFromEmittersAtSampleLocations(tempEmitters,sampleLocations);

      fluxRemainders = fluxes - evaluationFluxes;

      % keep track of the best set of emitters so that they can be returned at end 
      temp = sum(fluxRemainders .^ 2); 
      if temp < minScore
         minScore = temp;
         bestEmitters = tempEmitters;
      end




      % %%%%%%%%%%%%%%%%%
      % Acceptance policy
      % %%%%%%%%%%%%%%%%%
      if  temp < lastFlux % always accept lower answers
         emitters = tempEmitters;
         lastFlux = temp;
         previousLowestTotalFlux = lastFlux;
      else % The error went up!
         if mod(iteration, acceptanceFrequency) == 0
            increase = temp - lastFlux;
            percentIncrease = increase/lastFlux; 
            if percentIncrease < maxAllowablePercentageIncrease %accept this answer
               emitters = tempEmitters;
               lastFlux = temp;
               previousLowestTotalFlux = lastFlux;
            end 
         end 
      end



      % adjust strengthSigma based on the current remaining amount of flux.
      strengthSigma = previousLowestTotalFlux / sigmaConstant;


      % determine when to quit searching.
      if iteration > numberOfIterations
         emitters = bestEmitters;
         stillWorking = false;
      end
      
   end % of while still working
   
   fprintf('\n');  % shift onto the next line
end % of FMA







function fluxes = renderFromEmittersAtSampleLocations(emitters,measurementLocations)
   % Written by Jack Buffington 2018
   
   % emitters are in the form [X,Y, activity] with X & Y in meters 
   % sampleLocations are in the form[X, Y] with meters as the units

   % remove any emitters that have zero strength to speed up render times
   emitters = emitters(emitters(:,3) > 0,:);
   
   % each row of distanceMatrix corresponds to an emitter
   % each column of distanceMatrix corresponds to a sample location
   distanceMatrix = pdist2(emitters(:,1:2),measurementLocations);
   
   % Now convert this to into 1/4*pi*distance^2 and get rid of distances that are zero
   distanceMatrix(distanceMatrix == 0) = .01; 
   distanceMatrix = distanceMatrix .^2;
   distanceMatrix = distanceMatrix * 4 * pi;
   distanceMatrix = 1 ./ distanceMatrix;
   intensities = emitters(:,3);
   fluxes = (intensities' * distanceMatrix)';
end
