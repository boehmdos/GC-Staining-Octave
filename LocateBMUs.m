% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function is the bottle-neck of GC staining.
% In Octave 9.3.0, this sequential processing was faster or more reliable than any tested alternative.
% If you are from the future, keep an open eye for alternatives.
% If you use Matlab, pdist2 is much faster (not in Octave 9.3.0).

% This function finds for every mass spectrum in the chromatogram the most similar spectrum (Best Matching Unit, BMU) on the reference map (SOM).
% To this end, the Euclidean distance (= difference) is calculated between every spectrum on the reference map and the currently processed spectrum of the chromatogram.
% The spectrum with the smallest distance is the most similar one.
% It is selected as BMU, and its coordinates and the calculated distance are recorded for the retention time of the processed chromatogram spectrum.
% The recorded chromatograms are then used to determine a color for the mass spectrum in the chromatogram and to draw a substance and a quantitative map.

function BMUs = LocateBMUs(MsSom, Rt, TIC, MS, MinIntensity = 0)

SamplesBMUs = NaN(size(Rt, 1),2); % Create the array to store the BMU coordinates for each spectrum. If a spectrum is not processed because its TIC is too low, no coordinates will be written for it into this array, and it will keep the unassigned coordinates [NaN NaN].
SamplesLowestDistances = NaN(size(Rt, 1),1); % The same approach is used for the distances.

if ( MinIntensity > 0 ) % This is the process if the user stated a minimum intensity for the TIC. Here, all spectra with a too low TIC are not processed, saving some time.
IdxIntensity = [find(TIC >= MinIntensity)]; % Identify the spectra with a TIC higher than the requested minimal intensity. These will be processed.
SpectraToProcess = size(IdxIntensity,1);
printf("=>> Number of spectra to process: %d\n", SpectraToProcess); % Inform the user about the amount of work to be done.
  for i = 1:SpectraToProcess % All the spectra that were identified as intense enough are processed.
    j = IdxIntensity(i); % Look into the list of intense enough spectra to find its row in the chromatogram.
    CurrentSample = reshape(MS(j,:),1,1,size(MS,2)); % Place the current spectrum in the same dimension (3) as the spectra in the reference map, so that their difference can be calculated easily.
    CurrentDistMap = sqrt(sumsq((bsxfun(@minus,MsSom,CurrentSample)),3)); % Calculate the differences (Euclidean distances) between the current spectrum from the chromatogram with *all* the spectra in the reference map. Make a list.
    SamplesLowestDistances(j) = min(min(CurrentDistMap)); % Find the smallest distance in the list and record it in the list prepared at the beginning. This entry corresponds to the BMU.
    [SamplesBMUs(j,1),SamplesBMUs(j,2)] = find (CurrentDistMap == SamplesLowestDistances(j)); % Identify the entry of the BMU and record its coordinates in the list prepared at the beginning.
    if(mod(i,100) == 0) %Inform the use about the progress
       Countdown = (SpectraToProcess - i);
       printf("=>> Spectra remaining %d\n", Countdown);
    endif
  end

else
SpectraToProcess = size(MS,1);
printf("=>> Number of spectra to process: %d\n", SpectraToProcess); % This is the process if the user did not state a minimum intensity for the TIC. Here, all spectra are processed.
  for i=1:SpectraToProcess % All spectra are processed.
    CurrentSample = reshape(MS(i,:),1,1,size(MS,2)); % Place the current spectrum in the same dimension (3) as the spectra in the reference map, so that their difference can be calculated easily.
    CurrentDistMap = sqrt(sumsq((bsxfun(@minus,MsSom,CurrentSample)),3)); % Calculate the differences (Euclidean distances) between the current spectrum from the chromatogram with *all* the spectra in the reference map. Make a list.
    SamplesLowestDistances(i) = min(min(CurrentDistMap)); % Find the smallest distance in the list and record it in the list prepared at the beginning. This entry corresponds to the BMU.
    [SamplesBMUs(i,1),SamplesBMUs(i,2)] = find (CurrentDistMap == SamplesLowestDistances(i)); % Identify the entry of the BMU and record its coordinates in the list prepared at the beginning.
    if(mod(i,100) ==0) %Inform the use about the progress
       Countdown = (SpectraToProcess - i);
       printf("=>> Spectra remaining %d\n", Countdown);
    endif
  end
endif

%Compile everything nicely for output as a struct.
BMUs.rt_min = Rt;
BMUs.tic = TIC;
BMUs.coordinates = SamplesBMUs;
BMUs.distances = SamplesLowestDistances;

% Status update
fdisp (stdout, "=> Mass spectra located on reference map")
end

