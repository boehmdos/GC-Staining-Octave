% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function plots a substance map and saves it as png.
% BMUs are drawn in a dot plot on their determined coordinates in their assigned color. The drawing order is determined by the TIC, so that dots og high intensity are drawn topmost. The dots are slightly transparent to show underlying dots.
% Absent entries, entries with a TIC below the requested minimal intensity, entries with a too high difference to their BMU, and entries outside the hue/saturation maps are not drawn.

function y = PlotSubstanceMap(FileName, Folder, Time, TIC, Locations, RGB, SomSize, Deselection)

% Make invisible the entries in the list of too low intensity/too high difference entries that was created in a previous function.
if ( Deselection > 0 ) % Check if the list of filtered values exists.
Locations(Deselection(:), 1:2) = repmat([NaN, NaN], size(Deselection,1),1); % Set the locations of all filtered scans/BMUs to NaN. This way, they will not be drawn in the graph.
endif

% Make invisible all spectra/BMUs that were outside the hue/saturation map.
IdxNoColor = find(isnan(RGB(:,1))); % Find all entries that have a NaN in their RGB values. Only the first column, red, is inspected here, since for an unassigned color, all three channels should be NaN.. Should. This is potential point of failure.
Locations(IdxNoColor(:), 1:2) = repmat([NaN, NaN], size(IdxNoColor,1),1); % All entries without RGB get an unknown location, NaN, assigned. This way, they will not be drawn in the graph.

SubstanceMapData = [TIC, Locations, RGB]; % Collect the information needed to draw the substance map: TIC, x and y coordinates, RGB values
SubstanceMapData = sortrows(SubstanceMapData, 1); % Sort the input according to TIC, so that intense dots are plotted last and are on top.

figure('Name','Substance Map') % Create a new figure item.
SubstanceMap = scatter(SubstanceMapData(:,2), SubstanceMapData(:,3), 49, SubstanceMapData(:,4:6), "filled", "markerfacealpha", 0.7); % Draw the spectra/BMUs as slightly enlarged, slightly transparent dots, with the assigned color (column 4, 5, 6), at the locations of the BMUs (columns 2, 3). Note that the coordinates are interpreted here as xy (right, up), while the hue and saturation map used ij (down, right).
box on; % Draw axes also on top and on the right.
axis ([0 SomSize(1) 0 SomSize(2)], "square"); % Adjust the axis to the size of the reference map, and make the map square.

SubstanceMapFilename = strcat(Folder, filesep, FileName, '_SubstanceMap_', Time, '.png'); % Create a file name for the output figure: name of the input file, descriptor, time at the start of processing.
saveas(SubstanceMap, SubstanceMapFilename); % Save as png.

% Status update
fdisp (stdout, "=> Substance map saved")
end
