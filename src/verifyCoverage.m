function [trackGap, fieldOfRegard, isCompliant] = verifyCoverage(altitude, totalOrbits, targetLat, maxOffNadir, R_E)
% Proves if the off-nadir roll is able to cover gaps between ground tracks
% at specific latitude.

    % Total circumference of the equator divided by total orbits.
    % Gives Gap
    equatorialGap = (2 * pi * R_E) / totalOrbits;
    
    % Gap shrinks as move away from equator.
    trackGap = equatorialGap * cosd(targetLat);
    
    slantRange = slantRangeCalculator(altitude, maxOffNadir, R_E);
    
    % Find exact Earth Central Angle.
    earthCentralAnglRad = asin((slantRange * sind(maxOffNadir)) / R_E);
    
    % Convert angle into physical ground distance across curve.
    reach = R_E * earthCentralAnglRad;
    
    % Total field is looking left and right.
    fieldOfRegard = 2 * reach;
    
        if fieldOfRegard >= trackGap
            isCompliant = 1;
        else
            isCompliant = 0;
        end
end