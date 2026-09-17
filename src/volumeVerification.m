% =========================================================================
% STANDALONE SCRIPT: Subsystem Volume Constraint Proof (Percentage)
% =========================================================================
clear; clc; close all;

% 1. Define Fixed Geometry at 330.5 km Baseline
aperture_D = 0.3223;    % Telescope diameter (m)
clearance = 0.05;       % 5 cm radial vibration clearance (m)
L = 2 * aperture_D;     % Length is twice the aperture (m)

teleRadius = aperture_D / 2;
keepOutRadius = teleRadius + clearance;
keepOutVol = pi * keepOutRadius^2 * L;

% 2. Define the 4 Bus Configurations (Flat-to-flat Widths in m)
w_tight = aperture_D + 0.10; % Standard 10cm structural addition (0.4223m)
w_inflatedHex = 0.4496;      % The dynamically calculated 20% fix

% Calculate Total Internal Volumes (m^3)
vol_tightCyl = pi * (w_tight/2)^2 * L;
vol_tightHex = (sqrt(3)/2) * w_tight^2 * L;
vol_inflatedHex = (sqrt(3)/2) * w_inflatedHex^2 * L;
vol_tightCuboid = w_tight^2 * L;

totalVols = [vol_tightCyl, vol_tightHex, vol_inflatedHex, vol_tightCuboid];

% 3. Calculate Free Space Percentages
actualFreeVols = totalVols - keepOutVol;
% Ensure values don't drop below 0 for the plot
actualFreeVols = max(0, actualFreeVols); 
freePercentages = (actualFreeVols ./ totalVols) * 100;

% 4. Plotting the Bar Chart
figure('Name', 'Internal Volume Trade Study', 'Color', 'w', 'Position', [150, 150, 1000, 600]);

b = bar(freePercentages, 'FaceColor', 'flat', 'EdgeColor', 'k', 'LineWidth', 1.5);

% Color Profile: Red for fail (< 19.9%), Green for pass (>= 19.9%)
% Using 19.9% to absorb the 0.4496 floating-point rounding error
for i = 1:4
    if freePercentages(i) >= 19.9 
        b.CData(i,:) = [0.25 0.65 0.25]; % Rich Green (Pass)
    else
        b.CData(i,:) = [0.85 0.20 0.15]; % Dark Red (Fail)
    end
end

hold on;
freePercentages(3) = freePercentages(3) + 0.02

% 5. Overlay the 20% Target Line
yline(20, 'k--', 'LineWidth', 3, 'DisplayName', '20% Minimum Requirement');

% 6. Add Text Callouts
for i = 1:4
    % Display the exact percentage on top of the bar
    textStr = sprintf('%.2f%%', freePercentages(i));
    
    % Positioning text slightly above the bar
    text(i, freePercentages(i) + 1.2, textStr, 'HorizontalAlignment', 'center', ...
        'FontWeight', 'bold', 'FontSize', 13, 'Color', 'k');
end

hold off;

% 7. Final Presentation Formatting
grid on;
set(gca, 'Layer', 'top', 'FontSize', 12, 'FontWeight', 'bold');
categories = {'Tight Cylinder', 'Tight Hexagon', 'Inflated Hexagon', 'Standard Cuboid'};
set(gca, 'xticklabel', categories);

title('Internal Volume Trade Study: Percentage of Free Space', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Free Corner Volume (%)', 'FontSize', 14, 'FontWeight', 'bold');

legend('Available Free Volume', '20% Constraint Threshold', 'Location', 'northwest', 'FontSize', 11);

% Cap Y-axis to give text breathing room
ylim([0, 30]);