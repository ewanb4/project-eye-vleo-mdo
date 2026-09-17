function [validOrbits, altArray] = findValidAltitudes(minAlt, maxAlt, mu, R_E, tau_E, tau_ES)
%   valid_orbits - A matrix containing [m (days), n (orbits), altitude (km)]
%   alt_array    - A sorted 1D array of just the valid altitudes for plotting

    validOrbits = [];

% Sweep through possible combinations of m (days) and n (orbits)
for m = 1:10 
    for n = floor(15 * m) : ceil(16.5 * m) 
        
        % The RGT / SSO Equation
        timeFactor = abs((tau_ES * tau_E) / (tau_E - tau_ES));
        a = mu^(1/3) * ( (m / (2 * pi * n)) * timeFactor )^(2/3);
        alt = a - R_E;
        
        % Filter by constraints
        if alt >= minAlt && alt <= maxAlt
            validOrbits = [validOrbits; m, n, alt];
        end
    end
end

% Extract just the altitudes and sort them from lowest to highest
    if ~isempty(validOrbits)
        altArray = unique(validOrbits(:, 3))';
    else
        altArray = [];
    end
end