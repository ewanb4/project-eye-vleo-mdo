% =========================================================================
% --- MECHANICAL PACKAGING: NADIR FACE FREE SPACE ---
% =========================================================================

% Pull the exact diameter at the 330.5 km baseline
baselineDiameter = apertureDiameter(baselineIdx);

% Calculate the geometric areas
nadirSquareArea = baselineDiameter^2; 
telescopeHoleArea = pi * (baselineDiameter / 2)^2;

% Calculate the leftover space in the 4 corners
totalFreeSpace = nadirSquareArea - telescopeHoleArea;
spacePerCorner = totalFreeSpace / 4;

% Print the proof to the Command Window
fprintf('\n--- NADIR FACE PACKAGING PROOF (330.5 km) ---\n');
fprintf('Telescope Aperture Diameter: %.2f m\n', baselineDiameter);
fprintf('Total Free Space (4 Corners): %.4f m^2\n', totalFreeSpace);
fprintf('Usable Area per Corner:       %.4f m^2\n', spacePerCorner);
fprintf('-------------------------------------------\n\n');