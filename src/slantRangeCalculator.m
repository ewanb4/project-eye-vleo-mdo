function slantRangekm = slantRangeCalculator(altitude, maxOffNadir, R_E)
    
    % Converts Nadir angle to Rads
    offNadirRad = deg2rad(maxOffNadir);

    % Distance to satellite from Centre of Earth
    satDistance = R_E + altitude;

    % Calculates Slant Range
    slantRangekm = satDistance * cos(offNadirRad) - sqrt(R_E^2 - ...
        (satDistance * sin(offNadirRad))^2);

    % If not real, angle is pointing past horizon
    if ~isreal(slantRangekm)
        warning(['Off-nadir angle exceeds the Earth horizon at ' ...
            '%f km altitude.'], altitude);
        slantRangekm = NaN;
    end
end