function [inclinationDeg, velocity, orbitPeriodSec] = orbitCalculator(altitude, mu, J2, R_E, omega_dot)

    a = R_E + altitude; % Semi-major axis (km)
    n = sqrt(mu/(a^3)); % Mean Motion

    cosi = -(2 * omega_dot * a^2) / (3 * J2 * R_E^2 * n);

    if abs(cosi) > 1
        disp('SSO not possible')
        inclinationDeg = NaN;
        velocity = NaN;
        orbitPeriodSec = NaN;

    else
        % Inclindation Calculated in Degrees
        inclinationRad = acos(cosi);
        inclinationDeg = rad2deg(inclinationRad);
        
        % Velocity of circular orbit (km/s)
        velocity = sqrt(mu / a);
        
        % Orbit Period (Seconds)
        orbitPeriodSec = 2 * pi * sqrt(a^3 / mu);
    end

end 