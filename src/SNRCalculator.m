function snr = SNRCalculator(aperture, slantRange, velocity, gsd, wavelength)
% Uses Optical Payload Engineering Notes

Q_so = 500; % 1360 but only ~40% in optical wavelengths (Wm^-2)
albedo = 0.2; % Typically between 0.05 to 0.4
T_opt = 0.85; % Efficency of optics ~0.85-0.9
Q_eff = 0.9; % Sensor quantum efficiency
h_p = 6.63e-34; % Planck's constant
c = 3e8; % Speed of Light (m/s)

% Time Delay Integration - Can dramatically decrease mass
nTDI = 8; % Number of TDI Stages

% Convert to meters / meters per second
slantRangeM = slantRange * 1000;
velocityM = velocity * 1000;
t_integration = (gsd / velocityM) * nTDI; % Integration Time (s)

% Signal Calculation
signalConst = Q_so * albedo * (gsd^2) * (1/(8* slantRangeM^2)) * (wavelength / (h_p * c)) * T_opt * Q_eff * t_integration; 
signalTotalElectrons = signalConst * (aperture^2);

% SNR approximastion
snr = signalTotalElectrons / sqrt(signalTotalElectrons);