% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function imports the data on stains from csv-files that were prepared with the GC staining function.
% The first two rows are data on the GC file and the original staining conditions with labels in the first row.
% Line 4 onwards are the output of the original GC staining. Labels are found in the third row.

function [Original, Chromatogram, BMUs] = LoadStainingCSV(Filename,Sep = ",")

% Extract information on the original GC file and the original staining conditions.
documentation = csv2cell(Filename, Sep); % Import the csv with csv2cell, since it handles special characters better than dlmread.
Original.file = documentation(2,1); % Name of the origin GC file.
Original.time = documentation(2,2); % Time of the original stain with the GC staining function
Original.mzMin = documentation(2,5); % Minimum m/z used for the original stain
Original.mzMax = documentation(2,6); % Maximum m/z used for the original stain
Original.minIntensity = documentation(2,7); % Minimum Intenisty threshold used in the original stain
Original.SOM = documentation(2,9); % Name of the reference map used for the original stain

% Extract the data that will be used for restaining.
data = dlmread(Filename,Sep); % This function uses dlmread. This was the default choice in Octave 9.3.0, and it is a bit slow. Check for an alternative if you are from the future or using Matlab.

Original.somsize = [data(2,10), data(2,11)]; % Size of the reference map used in the original stain

Chromatogram.rt_ms = data(4:end, 1); % Retention times of the chromatogram in milliseconds
Chromatogram.rt_min = data(4:end, 2); % Retention times of the chromatogram in minutes
Chromatogram.tic = data(4:end, 3); % singal intensity (total ion current of the mass spectrometer) of the chromatogram

BMUs.rt_min = data(4:end, 4); % Retention times of the mass spectra in the stained chromatogram
BMUs.distances = data(4:end, 5); % Distances - differences between the spectra and their best-metching units in the reference map
BMUs.coordinates = data(4:end, 6:7); % Coordinates of the best-matching units on the reference map

endfunction
