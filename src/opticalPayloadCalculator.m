function [apertureDiameter, telescopeLen, otaMass] = opticalPayloadCalculator(slantRange, wavelength, targetGSD)
    
    % Convert slant range to meters.
    slantRangeM = slantRange * 1000;

    % Calculate Aperture Diameter using Rayleigh Criterion.
    apertureDiameter = (1.22 * wavelength * slantRangeM) / targetGSD;

    % Calculate Telescope Length Assuming double diameter.
    telescopeLen = 2 * apertureDiameter;
    
    % Use assumption for calculating Optical Telescope Assembly Mass.
    otaMass = 146 * (apertureDiameter ^ 1.27);


end 