% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0


% This function creates a list all instances in the chromatogram, where the TIC is lower than a requested minimum intensity or where the distance between the spectrum and the reference map is larger than the maximum distance.
% Peaks in the chromatogram that are too small can then be ignored in the following plotting functions, which reduces noise.
% Peaks where the spectrum is too different from the spectrum in the best matching unit can then be ignored in the following plotting function, which can reduce the number of dubious assignments.

function Deselection = TrimIntensityandDistance (TIC, MinIntensity = NaN, Distances, MaxDistance = NaN)

Deselection = [];

if ( MinIntensity > 0 ) % If a minimum intensity was stated by the user, find all lines where the TIC is lower than the minimal intensity.
   IdxIntensity = find(TIC < MinIntensity); % List all entries, where the TIC is less intense than the minimal intensity.
   Deselection = [IdxIntensity]; % Put the identified entries on the list.
endif

if ( MaxDistance > 0 ) % If a maximum distance was stated by the user, find all lines where the distance (difference) between the spectrum and the spectrum on the reference map is larger than the maximum distance.
   IdxDistance = find(Distances > MaxDistance); % List all entries, where the distance is greater than the maximum distance.
   Deselection = [Deselection; IdxDistance]; % Add the identified entries to the list.
endif

Deselection = [unique(Deselection)]; % Remove duplicate entries - those that have both too low intensity and too high distance.

% Status update
fdisp (stdout, "=> Results filtered for minimal intensity and maximum distance")

end
