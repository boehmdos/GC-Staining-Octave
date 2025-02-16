% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function plots a quantitative subtance map and saves it as a png.
% The intensities in each grid unit are summed up. The total intensitites are indicated on a dot plot in their repective grid coordinates. Color encodes the total intensity in each grid unit. Drawing order is from low to high total intensity, so that dots of high intensity are topmost.
% The summes intensities cover the orders of magnitude as requested by NumberofBins. With 4 bins, 4 orders of magnitudes are drawn, e. g. 10E8 to 10E4.
% Absent entries, entries with a TIC less than the lowest bin, entries with a too high difference to their BMU, and entries outside the hue/saturation maps are not drawn.


function y = PlotQuantitativeMap(FileName, Folder, Time, TIC, Locations, NumberofBins = 4, SomSize, Deselection, MinIntensity = NaN, MaxDistance = NaN)

% Make invisible the entries in the list of too low intensity/too high difference entries that was created in a previous function.
if ( Deselection > 0 ) % % Both low intensity signals and absent signals are depicted in white.Check if the list of filtered values exists.
Locations(Deselection(:), 1:2) = repmat([NaN, NaN], size(Deselection,1),1); % Set the locations of all filtered scans/BMUs to NaN. This way, they will not be drawn in the graph.
endif

% Entries with NaN coordinates are removed, otherwise the conversion of coordinates to indices doesn't work.
IdxNaN = isnan(Locations(:,1)); % Find all entries that have a NaN on the x-coordinate. Entries with a NaN *only* on the x or y coordinate should not exist. Should. This is potential breaking point.
Locations = Locations(~IdxNaN, 1:2); % Retain the locations that have valid coordinates.
TIC = TIC(~IdxNaN); % Extract the TICs of the entries with valid coordinates.

BMUIndex = [sub2ind(SomSize(1:2),Locations(:,1),Locations(:,2))]; % Convert the coordinates of the locations into indeces.

BMUIntensities = [BMUIndex, TIC]; % Link the indeces to the TICs.

% Totalize the intensities in each BMU.
% Thanks to Andrei Brobov for this solution. https://de.mathworks.com/matlabcentral/answers/156577-how-to-sum-group-values-in-a-matrix-based-on-their-index-values-in-first-column
[a,~,c] = unique(BMUIntensities(:,1)); % Find the index of all the BMUs that appear at least once in the list.
AccumulatedBMUIndex = [a, accumarray(c,BMUIntensities(:,2))]; % List the found indeces and sum up all their TICs as listed in c. The output is a BMU index with the totalized intensity in this BMU.

[QuantitativeBMUs(:,1), QuantitativeBMUs(:,2)] = ind2sub(SomSize(1:2), AccumulatedBMUIndex(:,1)); % Convert the indices back to xy-coordinates.
QuantitativeBMUs (:,3) = AccumulatedBMUIndex(:,2); % Combine the coordinates with the totalized intensities.
QuantitativeBMUs = sortrows(QuantitativeBMUs, 3); % Sort the array by TIC, so that the smallest values are plotted first and the highest values are plottest last, on top.
QuantitativeBMUs(:,4) = log10(QuantitativeBMUs(:,3)); % Calculate the log10 of the totalized intensities to be used in a log-scaled colormap.

figure('Name','Quantitative Map'); % Create a new figure item.
QuantitativeMap = scatter(QuantitativeBMUs(:,1), QuantitativeBMUs(:,2), 49, QuantitativeBMUs(:,4),"filled"); % Draw the spectra/BMUs as slightly enlarged, slightly transparent dots, at the locations of the BMUs (columns 1, 2). The color will be controlled by the log10 of the tolized intensity (column 4). Note that the coordinates are interpreted here as xy (right, up), while the hue and saturation map used ij (down, right).
box on; % Draw axes also on top and on the right.
axis ([0 SomSize(1) 0 SomSize(2)], "square"); % Adjust the axis to the size of the reference map, and make the map square.
colormap(flipud(viridis(NumberofBins))); % Create a discrete colormap with as many bins as requested. The color map is iinverted to have darker colors for higher intensities. The publication uses the colormap "Inferno" of Matplotlib. Viridis, the standard in Octave, is find, too.
caxis ([ceil(max(QuantitativeBMUs(:,4))) - NumberofBins, ceil(max(QuantitativeBMUs(:,4)))]); % Set the upper limit of the color map to accomodate the highest intensity. Set the lower limit according to upper limit and the number of bins.
c = colorbar; % Add a legend for the colors.


QuantitativeMapFilename = strcat(Folder, filesep, FileName, '_QuantitativeMap_', Time, '.png');  % Create a file name for the output figure: name of the input file, descriptor, time at the start of processing.
saveas(QuantitativeMap, QuantitativeMapFilename); % Save as png.

% The data of the quantitative map is saved as csv, for example for integration and quantitative analysis with some other software.
% The first two rows report the variables used in the quantitative map for future reference.
ParameterLabel = ostrsplit("Input File Name,Date Created,Minimum TIC Intensity,Maximum BMU Distance", ","); % Create the labels for the parameters used for this map.
Parameters = [{FileName, datestr(now(), "yymmdd_HHMMSS"), num2str(MinIntensity), num2str(MaxDistance)}]; % Piece the used parameters together.
% The third row labels the data output, which is from row 4 onwards.
OutputLabel = ostrsplit("x,y,totalized TIC(cts),log totalized TIC", ","); % Create the table header.
OutputData = QuantitativeBMUs; % Collect the data to be saved.
OutputData = num2cell(OutputData); % Convert of the data type so that it can be combined with the labels in a csv.
Output = [ParameterLabel; Parameters; OutputLabel; OutputData]; % Combine the labels with the data
OutputFilename = strcat(Folder, filesep, FileName, '_QuantitativeMap_', Time, '.csv');; %  % Create a file name for the output figure: name of the input file, descriptor, time at the start of processing.
cell2csv (OutputFilename, Output); % Save as csv.

% Status update
fdisp (stdout, "=> Quantitative substance map saved")

end
