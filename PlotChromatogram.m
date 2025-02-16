% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function plots a stained chromatogram and saves it as png.
% It is a conventional chromatogram, and to each scan retention time, the color assigned to the spectrum's BMU is shown in the background.
% Currently, the chromatogram is plotted as TIC of the mass spectra. If they are available, also the signals of other detectors (FID, or a SIM) could be plotted just as well.
% The colors are plotted from the assembled RGB values as image that is plotted first (and is therefore in the background). The image is originaly only 1 pixel wide, and it is stretched to a visible size.
% Both low intensity signals and absent signals are depicted in white.

function y = PlotChromatogram(FileName, Folder, Time, RtRGB, RGB, RtDetector, SignalDetector, Deselection)
pkg load image

% Make invisible the entries in the list of too low intensity/too high difference entries that was created in a previous function.
if ( Deselection > 0 ) % Check if the list of filtered values exists.
RGB(Deselection(:), 1:3) = repmat([1, 1, 1], size(Deselection,1),1); % Set the color of all entries on the list of filtered values to RGB 1 1 1, which is white.
endif

IdxNoColor = isnan(RGB); % Find all NaNs in the RGB values. Those BMUs were located outside the hue/saturation maps.
RGB(IdxNoColor) = 1; % Replace the NaNs by 1. This directly gives RGB 111, white. How convenient! How likely to break! If it breaks, replace it with the repmat approach that was used for Deselection.

IdxRt = find(RtDetector >= RtRGB(1) & RtDetector <= RtRGB(end)); % Find the retention times in the detector signal that are within the stained time range.
SignalPlot = SignalDetector(IdxRt, :); % Find the detector intensities in the stained time range.

RGB = reshape(RGB,size(RGB,1),1,3); % Change the dimensions of the array of RGB values, so that image understand it as RGB tripletts.

figure('Name','Chromatogram') % Create a new figure item.
stripes = imrotate(RGB, 90); % Rotate the array of RGB values so that the sequence of colors is in the same direction as the plotted gas chromatogram.
Chromatogram = image(stripes,'xdata',[RtRGB(1), RtRGB(end)],'ydata',[-0.2*max(SignalPlot) 1.2*max(SignalPlot)]); % Plot the array of RGB values as stripes. The size of this stripe image is defined to fit the retention times in the chromatogram and to be larger than the signal intensity.
hold on; % There is more to plot.
plot(RtRGB, SignalPlot,'black','linewidth',1); % Plot the gas chromatogram.
axis xy; % Change the presentation from ij (row/column, down/right) to xy (Cartesian, right/up).
axis ([RtRGB(1), RtRGB(end)]); % Adjust the range of the time axis to cut off undefined parts.
xlabel('Retention Time (min)'); % Label the x-axis.
ylabel('TIC (cts)'); % Label the y-axis.

ChromatogramFilename = strcat(Folder, filesep, FileName, '_Chromatogram_', Time, '.png'); % Create a file name for the output figure: name of the input file, descriptor, time at the start of processing.
saveas(Chromatogram, ChromatogramFilename); % Save as png.

% Status update
fdisp (stdout, "=> Stained chromatogram saved")
end
