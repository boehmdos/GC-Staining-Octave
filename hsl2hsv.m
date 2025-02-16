% Released under an MIT license by Stefan Böhmdorfer and Matthias Guggenberger, 2025.
% This is version 1.0, February 16, 2025.
% Developed and tested on Octave 3.9.0


function hsv = hsl2hsv(hsl)
    %converts a three column HSL Vector to HSV (based on wikipedia)

  if ( ndims(hsl) == 2 )
    H_hsl = hsl(:,1);
    S_hsl = hsl(:,2);
    L_hsl = hsl(:,3);
  elseif ( ndims(hsl) == 3 )
    H_hsl = hsl(:,:,1);
    S_hsl = hsl(:,:,2);
    L_hsl = hsl(:,:,3);
  else
    error("HSL input values should be 3 columns [H,S,L] as j in a 2-dimensional or k in a 3-dimensional array. This is not the case.")
  end

  H_hsv = H_hsl;
  LLMinusOne = reshape([L_hsl (1-L_hsl)],size(L_hsl)(1),size(L_hsl)(2),2);
  V_hsv = L_hsl + S_hsl .* min(LLMinusOne,[],3);

  if ( any(V_hsv == 0) )
    IdxZero = find(V_hsv == 0);
    IdxNonZero = find(V_hsv > 0);
    S_hsv(IdxZero) = 0;
    S_hsv(IdxNonZero) = 2 - (2 .* (L_hsl(IdxNonZero) ./ V_hsv(IdxNonZero)));
    S_hsv = S_hsv';
  else
    S_hsv = 2 - (2 .* (L_hsl ./ V_hsv));
  end
  if ( ndims(hsl) == 2 )
  hsv = [H_hsv S_hsv V_hsv];
  elseif ( ndims(hsl) == 3 )
  hsv = reshape([H_hsv S_hsv V_hsv],size(H_hsv)(1),size(H_hsv)(2),3);
  end

end
