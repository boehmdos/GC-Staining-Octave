% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function creates a list all instances in the chromatogram, where the TIC is lower than a requested minimum intensity or where the distance between the spectrum and the reference map is larger than the maximum distance.
% Peaks in the chromatogram that are too small can then be ignored in the following plotting functions, which reduces noise.
% Peaks where the spectrum is too different from the spectrum in the best matching unit can then be ignored in the following plotting function, which can reduce the number of dubious assignments.

function [TrimmedRt, TrimmedTIC, TrimmedCoordinates, TrimmedDistances] = TrimTime(Rt, RtMin, RtMax, TIC, Coordinates, Distances)

IdxTime = find(Rt > RtMin & Rt < RtMax); % List all entries, where the retention time is less than the minimum or more than the maximum.

TrimmedRt = Rt(IdxTime);
TrimmedTIC = TIC(IdxTime);
TrimmedCoordinates = Coordinates(IdxTime, :);
TrimmedDistances = Distances(IdxTime);

% Status update
fdisp (stdout, "=> Chromatogram clipped to the retention time window")

end
