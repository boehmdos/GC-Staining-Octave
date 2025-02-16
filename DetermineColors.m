% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function assigns color values to each BMU. They are assigned as hue, saturation and lightness, which is converted into red, green and blue.
% Hue depends on the angle form a reference line. The value is read from a look-up grid prepared in an previous function.
% Saturation depends on the distance from a center position. The value is read from a look-up grid prepared in an previous function.
% Lightness depends on the TIC. The highest TIC in the samples is assigned the value 0.5, all other peaks get lower values. The values are adjusted by an exponential function with the exponen alpha, to make smaller peaks more visible and to adjust for physiological non-linearity.
% BMUs with unknown coordinates (NaN, NaN) get white assigned as color, HSL 001, RGB 111. These BMUs are processed separatly from BMUs with known coordinates. Retention time is used to keep the BMUs in their chromatographic order.

function [HSL,RGB] = DetermineColors(Locations, TIC, HueSatMap, alpha = 0.65, Rt)

AllLocations = [Locations, TIC, Rt]; % Compile the coordinates of the BMU, the signal intensity and the retention time for recorded and processed spectrum in the chromatogram.

IdxNaN = isnan(AllLocations(:,1)); % Find all the NaNs in the coordinates. Spectra get the position NaN if their signal intensity was less than the requested minimal value and they were ignored when the BMUs were located.
UnknownLocations = [];
UnknownLocations = AllLocations(IdxNaN,:); % Group all BMUs that don't have a location assigned.
KnownLocations = AllLocations(~IdxNaN,:); % Group all BMUs that have a location assigned.

UnknownHSL = [repmat([0 0 1], size(UnknownLocations,1), 1), UnknownLocations(:,4)]; % Assign to all BMUs without an assigned location (they have NaN as location) the HSL color values 0, 0, 1. This is white. The retention time of each BMU is added so that the BMUs without and with assigned location can be combined later.

ColorIndices = sub2ind(size(HueSatMap.Hue),KnownLocations(:,1),KnownLocations(:,2)); % Convert the coordinates of the BMUs to linear indices to make things a bit easier (one-dimensional :D).
Hues = HueSatMap.Hue(ColorIndices); % The hue values of the BMUs are read from the hue map prepared earlier.
Sats = HueSatMap.Saturation(ColorIndices); % The saturation values of the BMUs are read from the saturation map prepared earlier.
TICScaled = (1 - normalize(KnownLocations(:,3), 'range', [0, 0.5])) .^alpha; % The lightness values of the BMUs are calculated from the normalized TIC. The highest TIC will get the lightness 0.5. Lower TICs will get lightness values between 0.5 an 0. If you must, you can also try higher values than 0.5, this will make everything darker, but also less colorful. Lightness values are adjusted by an exponential function with the variable alpha. Physiologically, our perception of lightness is not linear. Values less than 1 for alpha will highlight smaller peaks.
KnownHSL =[ Hues, Sats, TICScaled, KnownLocations(:,4)]; % Combine the hue, saturation and lightness values of each BMU. The retention time of each BMU is added so that the BMUs without and with assigned location can be combined later.

HSL = [UnknownHSL; KnownHSL]; % Merge the HSL values of the BMUs without and with assigned location.
HSL = sortrows(HSL, 4); % Sort them according to retention time, so that they are in order of elution again.
HSL = HSL(:,1:3); % Leave the retention time behind. This array will be returned.

HSV = hsl2hsv(HSL); % Convert the HSL to HSV. This is a detour, since hsl2rgb was not available at the time of writing for Octave 9.3.0.
RGB = hsv2rgb(HSV); % Convert HSV to RGB. This array will be returned.

% Status update
fdisp (stdout, "=> Colors assigned to mass spectra")

endfunction

