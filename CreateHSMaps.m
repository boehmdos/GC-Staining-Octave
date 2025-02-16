% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function creates two maps. One for hue and one for saturation. These maps will serve as lookup tables in a following function to convert into color the coordinates of the best-matching units that were determined in an earlier function.
% The script uses the Hue Saturation Lightness - color space, which uses cylindrical coordinates. Hue is the angle from an arbitrary reference line. Saturation is the distance from the center of the cylinder. These two will be determined using maps prepared in this function. Lightness is the distance along the cylinders's axis. This will be determined by the signal intensity in a following function.
% The two maps that are the output of this script are as large as the reference map. They list hue (angle) and saturation (radial distance) values for every grid position on the reference map.
% The user can request coordinates for the position of the center, request a radius (the dimension is grid units), and an angle to adjust the direction of the reference line for hue.
% Without user requests, the center is placed in the center of the reference map. And the radius is so large that it will cover the entire reference map.
% If the requested coordinates and radius do not cover the complete reference map, the grid units will have the value NaN. These positions will be assigned the color white in a following function, and they will be not considered at all in the Substance Map and the Quantitative Map.
% Now this might lead to some confusion if you follow the code. It is probably irrelevant to the users: some parts of the GC staining script use Cartesian xy (right, up) coordinates, while others use Row/Colum ij (down, right) coordinates, like this here. This does funny inversion and rotations - still the shown and saved output and the input variables agree. Therefore, in this function, if you plot the hue map, it points in the wrong direction.



function ColorMaps = CreateHSMaps(SomSize, HueAngle = 0, CenterCoordinatesX = NaN, CenterCoordinatesY = NaN, Radius = NaN)

% Some testing and allocation of values.

% If no Hue Angle is requested by the user, the Hue Angle is set to zero.
if ( HueAngle*0 != 0 ) % *0 is 0 for numbers and not 0 for NaN and empty values.
  HueAngle = 0;
endif


% If Center Coordinates are requested, they are used. If none are requested, the Center Coordiantes are the Center of the reference map.
if ( CenterCoordinatesX*0 == 0 ) % *0 is 0 for numbers and not 0 for NaN and empty values.
  Center(1) = CenterCoordinatesX; % Use the requested center position for i.
else
  Center(1) = SomSize(1)/2; % If no center is defined, the center is placed in the i-center of the reference map.
endif


% If Center Coordinates are requested, they are used. If none are requested, the Center Coordiantes are the Center of the reference map.
if ( CenterCoordinatesY*0 == 0 ) % *0 is 0 for numbers and not 0 for NaN and empty values.
  Center(2) = CenterCoordinatesY; % Use the requested center position for j.
else
  Center(2) = SomSize(2)/2; % If no center is defined, the center is placed in the j-center of the reference map.
endif

% If a Radius is requested, it is used. If none is requested, the Radius is chosen so that the entire reference map is covered.
if ( Radius*0 == 0 ) % *0 is 0 for numbers and not 0 for NaN and empty values.
  Radius = Radius; % use the requested radius
else
  Corners = [0 0; SomSize(1) 0; 0 SomSize(2); SomSize(1) SomSize(2)]; % Determine which corner of the reference map is the farthest from the Center Coordinates.
  Radius = max(sqrt(sumsq(Center - Corners, 2))); % The distance to the farthest corner is selected as radius.
endif


Center = round(Center); % The center coordinates are rounded to an integer value, since they will be used in an integer-based grid.
Radius = ceil(Radius); % The radius is rounded up to make troubles with the grid less likely.


% Hue
[HueXX,HueYY]= meshgrid(-(Radius - 0.5):(Radius - 0.5), -(Radius - 0.5):(Radius - 0.5)); % Create a grid based on the dimension of the radius. The subtraction of 0.5 places the grid center in the center of the central grid unit.
HueMap = atand(HueYY./HueXX); % Determine the inverse tangent for every grid unit in relation to the center of the grid. From this, an angle in relation to the baseline will be derived.

% For every quadrant, the relationship between the inverse tangent and the angle is different.
% Assign each grid unit to a quadrant.
idxQ1 = find(HueXX>=0 & HueYY >=0);
idxQ2 = find(HueXX<0 & HueYY >=0);
idxQ3 = find(HueXX<0 & HueYY <0);
idxQ4 = find(HueXX>=0 & HueYY <0);

% Convert the invert tangent into a n angle according to the quadrant.
% For the first quadrant, no conversion is necessary.
HueMap(idxQ2) =  HueMap(idxQ2)+180;
HueMap(idxQ3) =  HueMap(idxQ3)+180;
HueMap(idxQ4) =  HueMap(idxQ4)+360;
% No we have listed the angle to the baseline for every grid unit. This is basically Hue.

HueMap = HueMap + (HueAngle + 360); % The determined angles are shifted by the requested hue angle. This shift results in angles > 360° or < 0°. In the next line, the remainder of the division by 360° is used to obtain only angles between 0° and 360°. To make this work properly, a full circle of 360 is added here.
HueMap = rem((HueMap/360), 1); % Normalize to 360° = 1. Report only the digits after the comma, so that all angles are between 0 an 1 (0° and 360°).
HueMap(isnan(HueMap)) = 0; % For uneven grid dimensions, the grid unit in the center is NaN. This replaced by 0 here.
%image(HueMap, 'CDataMapping','scaled'); % Show a picture of the hue map. The direction of 0° might be different from what you see in the stained maps. See the last comment before the function for an explanation.


% Saturation
[SatXX,SatYY]= meshgrid(-(Radius - 0.5):(Radius - 0.5), -(Radius - 0.5):(Radius - 0.5)); % Create a grid based on the dimension of the radius. The subtraction of 0.5 places the grid center in the center of the central grid unit.
SatXX = SatXX./Radius; % Normalize the units of the grid dimensions to radius.
SatYY = SatYY./Radius; % Normalize the units of the grid dimensions to radius.
SatMap = sqrt(SatXX.^2+SatYY.^2); % Calculate the distance of every grid unit from the center. This is basically Saturation.
%image(SatMap, 'CDataMapping','scaled'); % uShow a picture of the saturation map.

% Saturation cannot be larger than 1 by definition.
% Here, all grid units that have a saturation larger than 1 are filled with NaN.
HueMap(SatMap > 1) = NaN; % Assign all grid units in the hue map that correspond to a saturation > 1 the value NaN.
SatMap(SatMap > 1) = NaN; % Assign all grid units in the saturation map that haveo a saturation > 1 the value NaN.

% Depending on the center coordinates and the radius, some parts of the hue and saturation maps might be outside the reference map.
% Here, this excess is identified and removed.
% First, identify what will remain.
MapCoordinatesX = [1 : size(HueMap, 2)]; % List the coordinate of the grid of the hue and saturation maps as they were prepared.
MapCoordinatesY = [1 : size(HueMap, 1)]; % List the coordinate of the grid of the hue and saturation maps as they were prepared.
RequestedCoordinatesX = MapCoordinatesX(:) - Radius + Center(2); % The grid units of the hue and saturation maps will have these coordinates on the reference map, once they are are placed in the requested (Center, Radius) position.
RequestedCoordinatesY = MapCoordinatesY(:) - Radius + Center(1); % The grid units of the hue and saturation maps will have these coordinates on the reference map, once they are are placed in the requested (Center, Radius) position.
CoordinatesWithinSomX = find(RequestedCoordinatesX > 0 & RequestedCoordinatesX <= SomSize(2)); % Identify the requested coordinates that will be within the reference map.
CoordinatesWithinSomX = [CoordinatesWithinSomX]; % Some magic required by Octave, otherwise all the values in the array well be Val.
CoordinatesWithinSomY = find(RequestedCoordinatesY > 0 & RequestedCoordinatesY <= SomSize(1)); % Identify the requested coordinates that will be within the reference map.
CoordinatesWithinSomY = [CoordinatesWithinSomY]; % Some magic required by Octave, otherwise all the values in the array well be Val.
% Then crop the maps to what will remain.
HueMapCropped = HueMap(CoordinatesWithinSomY(1):CoordinatesWithinSomY(end), CoordinatesWithinSomX(1):CoordinatesWithinSomX(end)); % Extract the grid units of the hue map that will within the reference map.
SatMapCropped = SatMap(CoordinatesWithinSomY(1):CoordinatesWithinSomY(end), CoordinatesWithinSomX(1):CoordinatesWithinSomX(end)); % Extract the grid units of the saturation map that will within the reference map.
% Prepare two NaN array as large as the reference map. The hue and saturation maps will be pasted into this in the requested place.
HueFullSizeMap = nan(SomSize(1), SomSize(2)); % Create an array of NaNs with the same dimensions as the reference map for hue.
SatFullSizeMap = nan(SomSize(1), SomSize(2)); % Create an array of NaNs with the same dimensions as the reference map for saturation.
% Paste the cropped hue and saturation maps in the requested position
HueFullSizeMap(RequestedCoordinatesY(CoordinatesWithinSomY(1)) : RequestedCoordinatesY(CoordinatesWithinSomY(end)), RequestedCoordinatesX(CoordinatesWithinSomX(1)) : RequestedCoordinatesX(CoordinatesWithinSomX(end))) = HueMapCropped; % Replace all NaNs with the cropped hue map at the requested position in the NaN array.
SatFullSizeMap(RequestedCoordinatesY(CoordinatesWithinSomY(1)) : RequestedCoordinatesY(CoordinatesWithinSomY(end)), RequestedCoordinatesX(CoordinatesWithinSomX(1)) : RequestedCoordinatesX(CoordinatesWithinSomX(end))) = SatMapCropped; % Replace all NaNs with the cropped hue map at the requested position in the NaN array.

ColorMaps.Hue = HueFullSizeMap; % Save the prepared array as lookup grid for hue in the output variable.
ColorMaps.Saturation = SatFullSizeMap; % Save the prepared array as lookup grid for saturation in the output variable.

% Status update
fdisp (stdout, "=> Hue and saturation maps created")

end
