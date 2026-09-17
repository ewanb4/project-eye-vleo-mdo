% CONSTANTS
EARTH_RADIUS = 6378; % (RE) km
EARTH_GRAV_PARAM = 398600.44; % (mu) km^3/s^2 
J2_CONSTANT = 0.00108263; 
MAX_ALT = 600; %(km)
MIN_ALT = 200; %(km)
PRECESSION_RATE = 1.99106 * 10^(-7); % (Omega-dot) rad/s
WAVELENGTH_LIGHT = 550e-9; % m
GSD = 1; % 1m resolution
MAX_OFF_NADIR = 45; % degrees
TAU_E = 86164.09;  % 1 Sidereal Day
TAU_ES = 31556926; % 1 Solar Year
TARGET_LAT = 40; % degrees (Worst case Scenario))
h_p = 6.63e-34; % Planck's constant
c = 3 * 10^8;