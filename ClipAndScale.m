% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0

% This function cuts away all data that is outside the requested retention time window.
% It also cuts away all m/z intensities that are outside the requested m/z window, both in the mass spectra of the chromatogram and of he reference map (SOM).
% Intensities are then normalized within each spectrum
% This ensures that the m/z in the chromatogram and the reference cover the same spectral range and are comparable.

function [Chromatogram, SOM] = ClipAndScale(ImportedOpenChromCSV, Som, MzMinSom, RtMin, RtMax, MzMin, MzMax)

% Shorten the chromatogram to the requested retention times.
  IdxTime = find(ImportedOpenChromCSV.rt_min >= RtMin & ImportedOpenChromCSV.rt_min <= RtMax); % Identify the rows that represent retention times that are within the determined window.
  PreparedChromatogram.tic = ImportedOpenChromCSV.tic(IdxTime); % Extract the Total Ion Current for the retention time window.
  PreparedChromatogram.rt_min = ImportedOpenChromCSV.rt_min(IdxTime); % Extract the retention times in minutes for the retention time window.
  PreparedChromatogram.rt_ms = ImportedOpenChromCSV.rt_ms(IdxTime); % Extract the retention times in milliseconds for the retention time window.

% Normalize ("scale") the mass spectra in the chromatogram so that they are comparable to the spectra in the reference map. Then, clip the sclaed mass spectra in the chromatogram to the requested m/z range and retention time range.
  IdxMzMin = find (ImportedOpenChromCSV.mzs == MzMin); % Identify the column that represents the lowest m/z.
  IdxMzMax = find (ImportedOpenChromCSV.mzs == MzMax); % Identify the column that represents the highest m/z.
  ImportedOpenChromCSV.mzs_shortened_clipped = ImportedOpenChromCSV.mzs(IdxMzMin:IdxMzMax); % Extract a list of the m/z that are within that m/z window to act as a label later.
  ImportedOpenChromCSV.intensities_scaled = ImportedOpenChromCSV.intensities./max(ImportedOpenChromCSV.intensities,[],2); % Perform a row-wise normalization to set the intensity of the base peak (the most intense peak) to one.
  PreparedChromatogram.intensities = ImportedOpenChromCSV.intensities_scaled(:,IdxMzMin:IdxMzMax); % Extract the m/z intensities that are within the requested m/z range.
  PreparedChromatogram.intensities = PreparedChromatogram.intensities(IdxTime,:); % From that, extract the m/z intensities that are within the requested retention time range.
  Chromatogram = PreparedChromatogram; % Send it to the output variable. I know, it's redundant.

% Clip the mass spectra in the reference map. It is not necessary to normalize the mass spectra, since the reference map was trained with normalized mass spectra. Normalization has been done earlier, outside this script and outside the staining script.
  ClippedSom = Som(:,:,(MzMin - MzMinSom + 1) : (MzMax - MzMinSom + 1)); % Extract the m/z intensities that are within the requested m/z range. The columns that represent the lowest and the highest m/z are calculated based on the lowest m/z in the SOM as stated by the used, and under the asusmption the there is one column per integer m/z. Information on the m/z is not saved in the SOM file. We hadn't thought of that.
  SOM = ClippedSom; % Send it to the output variable. I know, it's redundant.

% Status update
  fdisp (stdout, "=> Chromatogram and spectra clipped to the requested sizes")

endfunction
