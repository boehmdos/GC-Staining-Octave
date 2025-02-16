% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% The script loads GC-MS data from csv-files. To convert the vendor-specific files to the generic csv, we used OpenChrom https://www.openchrom.net/

% This function imports GC-MS data from csv-files that were saved from OpenChrom.
% The first three columns are expected to be retention data: retention time in milliseconds, retention time in minutes, retention as retention index.
% Columns 4 to the end state the intensities of individual ions as recorded by the mass spectrometer. Spectral resolution is nominal, 1 m/z, integer values.
% Line 1 are column labels. Of interest are the labels of the mass spectra, the m/z, from column 4 onwoards.

function y = LoadOpenChromCSV(Filename,Sep = ",")
data = dlmread(Filename,Sep); % This function uses dlmread. This was the default choice in Octave 9.3.0, and it is a bit slow. Check for an alternative if you are from the future or using Matlab.

mzs = data(1,4:end); % Collect the m/z labels
intensities = data(2:end,4:end); % Collect the signal intensities for each MS scan of the chromatogram and each mz in the scan.
numberOfScans = size(intensities(:,1), 1); % Count the number of scans in the chromatogram
RT_ms = data(2:end,1); % Collect the retention time of each scan.
RT_min = RT_ms/60000; % Convert the retention times into decimal minutes, because chromatographers are used to this unit. Yes, that could also be read in the imported data.
TIC = sum(intensities,2)'; % Calculate a Total Ion Current from the collected mass spectra.

% Nicely pack all the data in a struct for export and further use.
chromatogram.rawdata = data;
chromatogram.mzs = mzs;
chromatogram.rt_ms = RT_ms;
chromatogram.rt_min = RT_min;
chromatogram.nrscans = numberOfScans;
chromatogram.intensities = intensities;
chromatogram.filename = Filename;
chromatogram.tic = TIC';
y = chromatogram;
endfunction
