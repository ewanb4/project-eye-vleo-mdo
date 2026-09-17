function [finalAperture, finalFocalLenMin,finalFocalLenMax, finalSNR, finalOtaMass, finalPixelPitchMin_um, finalPixelPitchMax_um] = optimisePayload(minAperture, slantRange, velocity, gsd, wavelength)

% Set starting points.
currentAperture = minAperture;
currentSNR = SNRCalculator(currentAperture, slantRange, velocity, gsd, wavelength);

% Prevent infinite Loops
maxIterations = 50000;
iteration = 0;

while currentSNR < 100 && iteration < maxIterations
    % Increase Diameter by 1mm
    currentAperture = currentAperture + 0.0001;
    
    % Recalculate SNR for new Diameter
    currentSNR = SNRCalculator(currentAperture, slantRange, velocity, gsd, wavelength);
    
    iteration = iteration + 1;
end 

if iteration == maxIterations
    warning("SNR Optimisation Failure");
end

finalAperture = currentAperture;

% Based on 3 - 15 times Focal Number
finalFocalLenMin = 6 * finalAperture;
finalFocalLenMax = 30 * finalAperture;

finalSNR = currentSNR;
finalOtaMass = 146 * (finalAperture ^ 1.27);

% --- SENSOR PROCUREMENT ENVELOPE ---
    % Calculate the exact pixel size bounds required to maintain a 1.0m GSD
    slantRange_m = slantRange * 1000;
    
    % Minimum Pixel Size (Matches the f/6 minimum telescope)
    finalPixelPitchMin_um = ((gsd * finalFocalLenMin) / slantRange_m) * 1e6;
    
    % Maximum Pixel Size (Matches the f/30 maximum telescope)
    finalPixelPitchMax_um = ((gsd * finalFocalLenMax) / slantRange_m) * 1e6;
end



