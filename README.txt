This folder has the files for the point source renderer:
FMA -  This is the flux match annealing algorithm.  It takes a set of emitters with 
         an activity of zero and optimizes their activites to closely match the flux 
         at the provided measurements.
getEmitters - This takes a set of suggested source locations and outputs a set of 
         emitters in a grid within a specified radius of these locations.
getMeasurements - Comes up with a set of measurement locations in the same manner as 
         getEmitters.m except that the measurements are outside of the specified 
         radius and optionally have some jitter in their postions.  It then 'takes 
         measurements' from a provided flux map in the requested region.  Finally it 
         triangulates the measurement locations. 
ISR - This function takes a set of measurements and a triangulation.  It uses them
         to generate a dense flux map within all of the triangles.  
PSR -  This renders a dense map of gamma flux
PSR_specificLocations - This renders flux only at the specified locations.  
         It is used by the flux match annealing algorithm because a dense map isn't 
         needed.
renderFluxMapFromImage - All of these examples use a set of emitters in a simple 
         grid.  This file makes it easy to render flux maps from image files that 
         represent source maps.
testFMA - tests the flux match annealing algorithm.  Compares actual and estimated 
         source maps.
testFMAandPSRworkflow - tests the flux match annealing to point source renderer 
         workflow.  Compares actual and estimated source maps as well as actual and
         estimated flux maps.
testGetEmittersAndMeasurements.m - Tests the getEmitters and getMeasurements 
         functions.  Plots out suggested locations, the emitters that were returned, 
         the measurement locations and the triangulation.
testISR - Tests the inverse square renderer function.  Shows actual and estimated
         flux maps.
testMap - This is used by testRenderFluxFromImage.m
testPSR - Shows the resulting flux map from two emitters of different activities in 
         rainbow colors.
testRenderFluxMapFromImage.m - Sets up some initial variable then calls 
         renderFluxMapFromImage.m  
testTGM - Uses the triangulated gradient method.  Compares estimated and actual 
         source locations.
testTGM_FMAandPSRworkflow - Uses the triangulated gradient method to estimate source 
         locations.  These estimates are used to place emitters which the flux match
         annealing algorithm optimizes to closely match the flux at the measurement
         locations.  These emitters are then passed to the point source renderer 
         which renders a dense flux map from these emitters.
TGM - This function takes a set of measurements and their triangulation and outputs
         a set of estimated source locations. 


