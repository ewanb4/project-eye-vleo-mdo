% =========================================================================
% STANDALONE SCRIPT: Debris Flux Heatmap from Excel
% =========================================================================
clear; clc; close all;

% 1. Read the Excel File
% Change 'DebrisData.xlsx' to match your actual file name
rawData = readmatrix('MASTER Data.xlsx');

% 2. Extract the axes and the data matrix
% readmatrix replaces text/blank cells with NaN. 
% Altitudes are in row 1 (columns 2 to end)
altitudes = rawData(1, 2:end);

% Inclinations are in column 1 (rows 2 to end)
inclinations = rawData(2:end, 1);

% The actual flux values make up the rest of the matrix
fluxMatrix = rawData(2:end, 2:end);

% 3. Plot the High-Resolution Heatmap
figure('Name', 'Debris Flux Analysis', 'Color', 'w', 'Position', [200, 200, 900, 550]);
[X_GRID, Y_GRID] = meshgrid(altitudes, inclinations);

% pcolor with shading interp creates a smooth, professional gradient
pcolor(X_GRID, Y_GRID, fluxMatrix);
shading interp; 

% Formatting the visual style
colormap('turbo'); % High contrast to show high/low flux zones
c = colorbar;
c.Label.String = 'Debris Flux (Objects / m^2 / yr)';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';

% 4. Add the Specific Target Point
hold on;
targetAlt = 350.5;
targetInc = 96.8;

% Plot a large, highly visible star marker at the target location
plot(targetAlt, targetInc, 'p', 'MarkerSize', 18, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

% Add a text label next to the point with a semi-transparent background for readability
labelString = sprintf(' Target Orbit\n (%.1f km, %.1f\\circ)', targetAlt, targetInc);
text(targetAlt + 10, targetInc, labelString, 'Color', 'w', 'FontWeight', 'bold', ...
    'FontSize', 11, 'BackgroundColor', [0 0 0 0.4], 'EdgeColor', 'w');
hold off;

% 5. Final Graph Formatting
grid on;
set(gca, 'Layer', 'top'); % Keeps grid lines visible above the heatmap
title('Orbital Debris Flux vs. Altitude and Inclination', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Inclination (Degrees)', 'FontSize', 12, 'FontWeight', 'bold');

% Set axis limits to perfectly bound your data
xlim([min(altitudes) max(altitudes)]);
ylim([min(inclinations) max(inclinations)]);