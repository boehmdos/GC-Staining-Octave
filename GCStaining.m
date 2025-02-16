% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% Remember to cite our paper, too, should you use this tool for science! It can be accessed for free here: https://doi.org/10.1016/j.talanta.2025.127541  Guggenberger, M.; Karageorgiou, C.; Benetková, B.; Potthast, A.; Rosenau, T.; Böhmdorfer, S. Visualising Analytes in Gas Chromatography by Staining and Substance Maps. Talanta 2025, 287, 127541.

% The script loads GC-MS data from csv-files. To convert the vendor-specific files to the generic csv, we used OpenChrom https://www.openchrom.net/
% Please see LoadOpenChromCSV.m and the read me for the expected layout in the file.

% I recommend to first apply a general stain with this script, without adjusting any parameters. And then restain with the script Restaining.m. If you have a recipe you like, it can ba applied here right away, of course.

% This could definitely be coded more effectively and elegantly. Our aim was to obtain a working (and hopefully robust) tool, that guarantees data integry, and that can be read and understood by others. And remember, we are chemists and not software engineers.


function y = GCStaining(ChromatogramFile, SomFile, MzMinSom, RtMinSet = NaN, RtMaxSet = NaN, MzMinSet = NaN, MzMaxSet = NaN, MinIntensity = NaN, MaxDistance = NaN,CenterCoordinatesX = NaN, CenterCoordinatesY = NaN, HueAngle = NaN, Radius = NaN, alpha = 0.65, NumberofBins = 4)

% -- Required Variables --
% These variables must be stated, or the script won't work.
% ChromatogramFile = "GrobMix_VF23_GC.csv";  The GC-MS chromatogram to be processed.
% SomFile = 'Talanta256SOM.h5';  The map of reference mass spectra prepared earlier or downloaded from Zenodo. For historical reasons, the file is expected to be a struct, and the actual map is expected to be called .FullMap. The expected format is (Cartesian coordinate x Cartesian coordinate x m/z). It is recommended to provide it as h5-file to reduce loading times. We usually prepared it from reference EI-MS spectra, normalized, integer resolution, in the range of 29 to 200 m/z as a self-organising map. Therefore "SOM" and "reference map" are used interchangeably.
% MzMinSom = 29;  lowest m/z in the used reference SOM


% -- Optional Variables --

% Data filtering
% RtMinSet = NaN;  Earliest retention as requested by the user. Only MS after this time will be processed. That can save some calculation time. Set it to NaN if you don't to use this. The script will then start with the first recorded spectrum.
% RtMaxSet = NaN;  Latest retention time as requested by the user. Only MS before this time will be processed, That can save some calculation time. Set it to NaN if you don't to use this. The script will then end with the last recorded spectrum.
% MzMinSet = NaN;  Lowest m/z as requested by the user. Set it to NaN if you don't to use this. The script will then set a mass range that is covered both by the MS and the reference map.
% MzMaxSet = NaN;  Highest m/z as requested by the user. Set it to NaN if you don't to use this. The script will then set a mass range that is covered both by the MS and the reference map.
% MinIntensity = NaN;  Threshold for the TIC intensity. Only MS with an equal or higher TIC will be processed. That can save some calculation time. Set it to NaN if you don't to use this. The script will then process all spectra within the set time range.
% MaxDistance = NaN;  Threshold for the distance (= Euclidean difference) between an MS in the chromatogram and its best-matching MS on the map. Use this to filter out badly assigned peaks. Set it to NaN if you don't use this. The script will then consider all determined best-matching units.

% Staining Recipes
% HueAngle = NaN;  Rotates the hues on the reference map. You can adjust the colors in the stain by this. Set to NaN or 0 if you don't want to modify this.
% CenterCoordinatesX = NaN;  Adjusts the center of the hue/saturation plane on the reference map. Set to NaN if you don't want to modify this. Then the center will be placed in the center of the map.
% CenterCoordinatesY = NaN;  Adjusts the center of the hue/saturation plane on the reference map. Set to NaN if you don't want to modify this. Then the center will be placed in the center of the map.
% Radius = NaN;  Adjusts the radius of the hue/saturation plane on the reference map. Set to [NaN, NaN] if you don't want to modify this. Then the radius will be set to cover the entire map.

% Plotting Adjustments
% alpha = 0.65;  Adjusts how lightness is calculated form TIC. This is the exponent in a power fucntion, therefore values below 1 will make lower intensities more visible. Values about 0.65 or 0.7 agree well with our non-linear perception of saturation..
% NumberofBins = 4;  Number of colors used in the quantitative map. This corresponds to the orders of magnitude shown. If the highest total intensity is 1E8 and the bins are set to 4, total intensities from 1E8 to 1E4 will be shown on the map.



% === Dependencies ===
%dependencies, io, hsl2hsv with link
pkg load io; % For cell2csv for the csv export.



% === Variables, Input Files and Variable Consolidation ===
Time = datestr(now(), "yymmdd_HHMMSS"); % Records the starting time. It will be used in the names of all output files, so that it is easy to see which belong together..

% Status update
fdisp (stdout, "=> Variables read")

% Call for patience
fdisp (stdout, "Loading the necessary data. This might take surprisingly long.")


% -- Load the required files --
LoadedChromatogram = LoadOpenChromCSV(ChromatogramFile); % Load the GC-MS data. The expected format is a csv as prepared by OpenChrom. The output is a struct with all the necessary data and some more.
% Status update
fdisp (stdout, "=> Chromatogram loaded")

% Load the reference map
load(SomFile); % Load the reference map with MS data that was prepared earlier or downloaded from Zenodo. The expected format is (Cartesian coordinate x Cartesian coordinate x m/z). It is recommended to provide it as h5-file to reduce loading times.
MsSom = SOM256.FullMap;
%Status update
fdisp (stdout, "=> Reference map loaded")


% -- Derive and Consolidate Variables --
SomSize = size(MsSom); % Determine the dimensions of the reference map.

RtMin = max([LoadedChromatogram.rt_min(1), RtMinSet]); % Check if there is data at the requested earliest retention time. If not, start processing when the recorded data starts.
RtMax = min([LoadedChromatogram.rt_min(end),RtMaxSet]); % Check if there is data at the requested latest retention time. If not, end processing when the recorded data ends.
MzMin = max([LoadedChromatogram.mzs(1), MzMinSom, MzMinSet]); % Check if there is data at the requested lowest m/z. If not, start processing at the lowest recorded m/z.
MzMax = min([LoadedChromatogram.mzs(end), MzMinSom + SomSize(3) - 1, MzMaxSet]); % Check if there is data at the requested highest m/z. If not, end processing at the highest recorded m/z.

[InputFolder InputFilename] = fileparts(which(ChromatogramFile));
OutputFolder = fullfile(InputFolder, InputFilename); % Collect the folder name the input file is saved in. All output will be saved in a subfolder with the same name as the input file.
% Status update
fdisp (stdout, "=> More variables established")

% Excited announcement
fdisp (stdout, "Start processing!")



% === Processing ===


% -- Adjust the chromatography data --
[PreparedChromatogram, PreparedSom] = ClipAndScale(LoadedChromatogram, MsSom, MzMinSom, RtMin, RtMax, MzMin, MzMax); % Clip the chromatogram to the requested retention time range. Clip the mass spectra in the chromatogram and the reference map to the requested range. Normalize the mass spectra for comparability.
% The status update is made in the function.


% -- Place every MS in the chromatogram on its place on the reference map --
BMUs = LocateBMUs(PreparedSom, PreparedChromatogram.rt_min, PreparedChromatogram.tic, PreparedChromatogram.intensities, MinIntensity); % For every mass spectrum in the chromatogram the most similar mass spectrum (BMU, Best Matching Unit) in the reference map. Calculate how different they are - this is the "distance", because we use the Euclidean distance as difference measure.
% The status update is made in the function.


% -- Create maps for hue and saturation --
HSMaps = CreateHSMaps(SomSize, HueAngle, CenterCoordinatesX, CenterCoordinatesY, Radius); % Two maps are created that are as big as the reference map. A map for hues (angle dependent) and a map for saturation (radius dependent). They will be used as look-up tables in the next step.
% The status update is made in the function.


% -- Determine colors from BMU coordinates --
[BMUs.HSL, BMUs.RGB] = DetermineColors(BMUs.coordinates, BMUs.tic, HSMaps, alpha, BMUs.rt_min); % Assign an HSL an RGB triplet to each spectrum in the chromatogram according to its best-matching unit
% The status update is made in the function.



% === Start of output ===


% -- Create the output folder --
status = mkdir(OutputFolder); % All files will be saved in a folder that has the some name as the chromatogram. The "status =" suppresses the warning that the folder exists


% -- Save into csv --
% I considered putting this block into a separate function. But I didn't like how many variable I would have had to hand over to the function.
% The file format is kept the same as in the published Python script.
% The first two rows report the variables used in the saved stain for future reference.
ParameterLabel = ostrsplit("Input File Name,Date Created,Time Range [min],,m/z Range,,Noise Limit[cts],alpha,SOM,SOM x size,SOM y size,,", ","); % Create the labels for the parameters that were used for staining.
Parameters = [{InputFilename, Time, num2str(RtMin), num2str(RtMax), num2str(MzMin), num2str(MzMax), num2str(MaxDistance), num2str(alpha)}, SomFile, num2str(SomSize(1)), num2str(SomSize(2)), NaN, NaN]; % Piece the used parameters together.

% The third row labels the data output, which is from row 4 onwards.
OutputLabel = ostrsplit("RT(ms),RT(min),TIC(cts),Rt(BMUs),Difference,x,y,H,S,L,R,G,B", ","); % Create the table header.
OutputData = [PreparedChromatogram.rt_ms, PreparedChromatogram.rt_min, PreparedChromatogram.tic, BMUs.rt_min, BMUs.distances, BMUs.coordinates, BMUs.HSL, BMUs.RGB]; % Piece together the data to tbe saved.
OutputData = num2cell(OutputData); % Convert of the data type so that it can be combined with the labels in a csv.
Output = [ParameterLabel; Parameters; OutputLabel; OutputData]; % Combine the labels with the data
OutputFilename = strcat(OutputFolder, filesep, InputFilename, '_StainedGC_', Time, '.csv'); % Create a file name for the output csv: name of the input file, descriptor, time at the start of processing.
cell2csv (OutputFilename, Output); % Save as csv.
% Status update
fdisp (stdout, "=> Results saved into csv")


% -- Identify spectra with too low TIC or too high distance --
BMUs.deselection = TrimIntensityandDistance(BMUs.tic, MinIntensity, BMUs.distances, MaxDistance);
% The status update is made in the function.


% -- Create and save a stained chromatogram --
PlotChromatogram(InputFilename, OutputFolder, Time, BMUs.rt_min, BMUs.RGB, PreparedChromatogram.rt_min, PreparedChromatogram.tic, BMUs.deselection);
% The status update is made in the function.


% -- Create and save a substance map --
PlotSubstanceMap(InputFilename, OutputFolder, Time, BMUs.tic, BMUs.coordinates, BMUs.RGB, SomSize, BMUs.deselection);
% The status update is made in the function.


% -- Create and save a quantitative map --
PlotQuantitativeMap(InputFilename, OutputFolder, Time, BMUs.tic, BMUs.coordinates, NumberofBins, SomSize, BMUs.deselection, MinIntensity, MaxDistance);
% The status update is made in the function.

% Status update
fdisp (stdout, "Done!")
fdisp (stdout, "Do you want to stain this chromatogram again with different settings?")
fdisp (stdout, "Use the function Restaining to load the saved csv and restain it!")

endfunction

