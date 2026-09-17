% =========================================================================
% --- ALBEDO VS ALTITUDE: OPTICAL MASS SENSITIVITY (HEATMAP) ---
% =========================================================================

% 1. Define the High-Resolution Grid
altRange = linspace(200, 600, 100);     % X-Axis: Altitude (km)
albedoRange = linspace(0.05, 0.4, 100); % Y-Axis: Earth Albedo

[AltGrid, AlbedoGrid] = meshgrid(altRange, albedoRange);
OtaMassGrid = zeros(size(AltGrid));

% 2. Optical Constants
Q_so = 500; 
T_opt = 0.85; 
Q_eff = 0.9; 
h_p = 6.63e-34; 
c = 3e8; 
gsd = 1.0; 
wavelength = 500e-9; 
minAperture = 0.1; 
mu = 3.986e5; 
r_earth = 6371; 

% 3. Run the Vectorized Sensitivity Loop
for i = 1:size(AltGrid, 1)
    for j = 1:size(AltGrid, 2)
        h = AltGrid(i,j);
        a = AlbedoGrid(i,j);
        
        % Orbital Math
        velocity = sqrt(mu / (r_earth + h)); 
        slantRangeM = h * 1000; 
        velocityM = velocity * 1000;
        t_integration = gsd / velocityM; 
        
        % The Signal Shortcut
        signalConst = Q_so * a * (gsd^2) * (1/(8 * slantRangeM^2)) * ...
                      (wavelength / (h_p * c)) * T_opt * Q_eff * t_integration; 
        
        exactAperture = sqrt(10000 / signalConst);
        finalAperture = ceil(exactAperture * 1000) / 1000; % Round up to mm
        
        if finalAperture < minAperture
            finalAperture = minAperture;
        end
        
        % OTA Mass Equation
        OtaMassGrid(i,j) = 146 * (finalAperture ^ 1.27);
    end
end

% 4. Plot the 2D Heatmap
figure('Name', 'OTA Mass Heatmap', 'Color', 'w', 'Position', [150, 150, 800, 550]);

% contourf creates a beautiful, smooth filled contour heatmap (50 color levels)
contourf(AltGrid, AlbedoGrid, OtaMassGrid, 50, 'LineStyle', 'none');

% Formatting the Heatmap
colormap('turbo'); % High contrast colormap (dark blue to dark red)
cbar = colorbar;
ylabel(cbar, 'OTA Telescope Mass (kg)', 'FontWeight', 'bold', 'FontSize', 12);

xlabel('Orbital Altitude (km)', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('Earth Albedo (Reflectivity)', 'FontWeight', 'bold', 'FontSize', 12);
title('Optical Payload Mass vs. Altitude and Albedo', 'FontSize', 15, 'FontWeight', 'bold');
subtitle('System packaging constraint mapping (SNR = 100)');

% Add a point for your chosen baseline design (Optional but highly recommended)
% Let's assume you locked in at 330.5 km altitude and 0.2 albedo
hold on;
plot(330.5, 0.2, 'wp', 'MarkerSize', 16, 'MarkerFaceColor', 'k', 'LineWidth', 1.5);
%text(340, 0.21, 'Phase B Baseline', 'Color', 'k', 'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', 'w');

grid on;
% =========================================================================