% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% Remember to cite our paper, too, should you use this tool for science! It can be accessed for free here: https://doi.org/10.1016/j.talanta.2025.127541  Guggenberger, M.; Karageorgiou, C.; Benetková, B.; Potthast, A.; Rosenau, T.; Böhmdorfer, S. Visualising Analytes in Gas Chromatography by Staining and Substance Maps. Talanta 2025, 287, 127541.

% The script loads staining data from csv-files created with the GCStaining script. Then you can stain the chromatogram again with adjusted parameters to obtain colors that make more sense with your separation.

function y = Restaining(StainingFile, RtMinSet = NaN, RtMaxSet = NaN, MinIntensity = NaN, MaxDistance = NaN, HueAngle = NaN, CenterCoordinatesX = NaN, CenterCoordinatesY = NaN, Radius = NaN, alpha = 0.65, NumberofBins = 4)


% -- Required Variables --
% These variables must be stated, or the script won't work.
StainingFile = "190329003_StainedGC_250211_154831.csv"; % The stained chromatogram to be reprocessed.


% -- Optional Variables --
% Data Filtering
% RtMinSet = NaN;  Earliest retention as requested by the user. Only MS after this time will be processed. That can save some calculation time. Set it to NaN if you don't to use this. The script will then start with the first recorded spectrum.
% RtMaxSet = NaN;  Latest retention time as requested by the user. Only MS before this time will be processed, That can save some calculation time. Set it to NaN if you don't to use this. The script will then end with the last recorded spectrum.
% MzMinSet = NaN;  Lowest m/z as requested by the user. Set it to NaN if you don't to use this. The script will then set a mass range that is covered both by the MS and the reference map.
% MzMaxSet = NaN;  Highest m/z as requested by the user. Set it to NaN if you don't to use this. The script will then set a mass range that is covered both by the MS and the reference map.

% Staining Recipes
% HueAngle = NaN; Rotates the hues on the reference map. You can adjust the colors in the stain by this. Set to NaN or 0 if you don't want to modify this.
% CenterCoordinatesX = NaN; Adjusts the center of the hue/saturation plane on the reference map. Set to NaN if you don't want to modify this. Then the center will be placed in the center of the map.
% CenterCoordinatesY = NaN; Adjusts the center of the hue/saturation plane on the reference map. Set to NaN if you don't want to modify this. Then the center will be placed in the center of the map.
% Radius = NaN; Adjusts the radius of the hue/saturation plane on the reference map. Set to [NaN, NaN] if you don't want to modify this. Then the radius will be set to cover the entire map.

% Plotting Adjustments
% alpha = 0.65; Adjusts how lightness is calculated form TIC. This is the exponent in a power fucntion, therefore values below 1 will make lower intensities more visible. Values about 0.65 or 0.7 agree well with our non-linear perception of saturation.
% NumberofBins = 4;


% === Dependencies ===
%dependencies, io, hsl2hsv with link
pkg load io; % For csv2cell in the import and cell2csv for the csv export.



% === Variables, Input Files and Variable Consolidation ===
Time = datestr(now(), "yymmdd_HHMMSS"); % Records the starting time. It will be used in the names of all output files, so that it is easy to see which belong together..

% Status update
fdisp (stdout, "=> Variables read")


% -- Load the required files --
% Original, BMUs, Chromatogram
[Original, Chromatogram, BMUs] = LoadStainingCSV(StainingFile); % Load the chromatogram stained earlier with the GCStaining function. The output is three structs with all the necessary data, some historical information and some more.
% Status update
fdisp (stdout, "=> Chromatogram loaded")


% -- Derive and Consolidate Variables --

RtMin = max([BMUs.rt_min(1), RtMinSet]); % Check if there is data at the requested earliest retention time. If not, start processing when the recorded data starts.
RtMax = min([BMUs.rt_min(end),RtMaxSet]); % Check if there is data at the requested latest retention time. If not, end processing when the recorded data ends.

[InputFolder InputFilename] = fileparts(which(StainingFile));
OutputFolder = fullfile(InputFolder, 'Restains'); % All output will be saved in a subfolder named "Restains".
% Status update
fdisp (stdout, "=> More variables established")

% Excited announcement
fdisp (stdout, "Start processing!")



% === Processing ===
[BMUs.rt_min_trim, BMUs.tic_trim, BMUs.coordinates_trim, BMUs.distances_trim] = TrimTime(BMUs.rt_min, RtMin, RtMax, Chromatogram.tic, BMUs.coordinates, BMUs.distances);


HSMaps = CreateHSMaps(Original.somsize, HueAngle, CenterCoordinatesX, CenterCoordinatesY, Radius); % Two maps are created that are as big as the reference map. A map for hues (angle dependent) and a map for saturation (radius dependent). They will be used as look-up tables in the next step.

[BMUs.HSL, BMUs.RGB] = DetermineColors(BMUs.coordinates_trim, BMUs.tic_trim, HSMaps, alpha, BMUs.rt_min_trim); % Assign an HSL an RGB triplet to each spectrum in the chromatogram according to its best-matching unit



% === Start of output ===
status = mkdir(OutputFolder); % All files will be saved in a folder that has the some name as the chromatogram. The "status =" suppresses the warning that the folder exists


% -- Save into csv --
% I considered putting this block into a separate function. But I didn't like how many variable I would have had to hand over to the function.
% The first two rows report the variables used in the saved stain for future reference.
ParameterLabel = ostrsplit("Input File Name,Date Created,Minimum Time [min],Maximum Time [min],Minimum Intensity [cts],Reference Map,Maximum Distance,Center X, Center Y,Radius,Hue Angle,alpha,", ","); % Create the labels for the parameters that were used for staining.
Parameters = horzcat(Original.file, Time, num2str(RtMin), num2str(RtMax), num2str(MinIntensity), Original.SOM, num2str(MaxDistance), num2str(CenterCoordinatesX), num2str(CenterCoordinatesY), num2str(Radius), num2str(HueAngle), num2str(alpha), 'Be kind to friends and strangers.'); % Piece the used parameters together.

% The third row labels the data output, which is from row 4 onwards.
OutputLabel = ostrsplit("RT(ms),RT(min),TIC(cts),Rt(BMUs),Difference,x,y,H,S,L,R,G,B", ","); % Create the table header.
OutputDataChromatogram = [Chromatogram.rt_ms, Chromatogram.rt_min, Chromatogram.tic];
OutputDataBMUs = [BMUs.tic_trim, BMUs.distances_trim, BMUs.coordinates_trim, BMUs.HSL, BMUs.RGB]; % Piece together the data to tbe saved.
OutputDataBMUs = [OutputDataBMUs; nan(size(OutputDataChromatogram, 1) - size(OutputDataBMUs, 1), size(OutputDataBMUs, 2))];
OutputData = [OutputDataChromatogram, OutputDataBMUs];
OutputData = num2cell(OutputData); % Convert of the data type so that it can be combined with the labels in a csv.
Output = [ParameterLabel; Parameters; OutputLabel; OutputData]; % Combine the labels with the data
OutputFilename = strcat(OutputFolder, filesep, InputFilename, '_RestainedGC_', Time, '.csv'); % Create a file name for the output csv: name of the input file, descriptor, time at the start of processing.
cell2csv (OutputFilename, Output); % Save as csv.
% Status update
fdisp (stdout, "=> Results saved into csv")


% -- Identify spectra outside the requested retention time, with too low TIC or too high distance --
BMUs.deselection = TrimIntensityandDistance(BMUs.tic_trim, MinIntensity, BMUs.distances_trim, MaxDistance);
% The status update is made in the function.


% -- Create and save a stained chromatogram --
PlotChromatogram(InputFilename, OutputFolder, Time, BMUs.rt_min_trim, BMUs.RGB, Chromatogram.rt_min, Chromatogram.tic, BMUs.deselection);
% The status update is made in the function.


% -- Create and save a substance map --
PlotSubstanceMap(InputFilename, OutputFolder, Time, BMUs.tic_trim, BMUs.coordinates_trim, BMUs.RGB, Original.somsize, BMUs.deselection);
% The status update is made in the function.


% -- Create and save a quantitative map --
PlotQuantitativeMap(InputFilename, OutputFolder, Time, BMUs.tic_trim, BMUs.coordinates_trim, NumberofBins, Original.somsize, BMUs.deselection, MinIntensity, MaxDistance);
% The status update is made in the function.

% Status update
fdisp (stdout, "Done!")

endfunction
