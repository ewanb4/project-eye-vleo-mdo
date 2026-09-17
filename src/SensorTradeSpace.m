% --- SENSOR PROCUREMENT TRADE SPACE ---
clear; clc; close all;
trade_constants

% 1. Input Your Final Winning Satellite State
CHOSEN_ALTITUDE = 400; % (km) REPLACE WITH YOUR OPTIMAL ALTITUDE
CHOSEN_APERTURE = 0.5; % (m) REPLACE WITH THE REQUIRED APERTURE AT THAT ALTITUDE
CHOSEN_SLANT = slantRangeCalculator(CHOSEN_ALTITUDE, MAX_OFF_NADIR, EARTH_RADIUS);
SLANT_M = CHOSEN_SLANT * 1000;

% 2. The Nyquist Requirement
X_PIXEL = GSD / 2; % (meters) Ground footprint of a single pixel

% 3. Calculate Focal Length Limits
f_min = 6 * CHOSEN_APERTURE;
f_max = 30 * CHOSEN_APERTURE;

% 4. Calculate Legal Pixel Pitch Envelope (Nyquist Corrected)
% p = (f * x_pixel) / SlantRange
pitchMin_um = ((f_min * X_PIXEL) / SLANT_M) * 1e6;
pitchMax_um = ((f_max * X_PIXEL) / SLANT_M) * 1e6;

% 5. Build the Trade Space Arrays
% Let's look at sensors from 2,000 to 20,000 pixels wide
numPixelsArray = 2000:500:20000; 

% Swath width is strictly dictated by Nyquist
swathWidth_km = (numPixelsArray .* X_PIXEL) ./ 1000; 

% --- Graph: The Sensor Trade Space ---
figure('Name', 'Camera Sensor Trade Space', 'Color', 'w');
hold on;

% Create a shaded region for the Valid Procurement Space
% The X-axis is Swath Width (driven by Number of Pixels)
% The Y-axis is Pixel Pitch
fill([min(numPixelsArray), max(numPixelsArray), max(numPixelsArray), min(numPixelsArray)], ...
     [pitchMin_um, pitchMin_um, pitchMax_um, pitchMax_um], ...
     [0, 0.4470, 0.7410], 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Valid Procurement Space');

% Plot the boundaries
yline(pitchMax_um, 'b-', 'LineWidth', 2, 'DisplayName', 'Max Limit (f = 30D)');
yline(pitchMin_um, 'b-', 'LineWidth', 2, 'DisplayName', 'Min Limit (f = 6D)');

% Add a secondary X-axis for Swath Width
ax1 = gca;
ax2 = axes('Position', ax1.Position, 'XAxisLocation', 'top', 'YAxisLocation', 'right', 'Color', 'none');
set(ax2, 'XLim', [min(swathWidth_km), max(swathWidth_km)], 'YLim', ax1.YLim);
ax2.YTick = []; % Hide Y ticks on the secondary axis
xlabel(ax2, 'Resulting Swath Width (km)');

% Formatting the primary axis
axes(ax1); % Make primary axis active again
grid on; box on;
xlabel('Number of Pixels (n)');
ylabel('Sensor Pixel Pitch (\mum)');
title(sprintf('Camera Sensor Trade Space at %d km Altitude', CHOSEN_ALTITUDE));
legend('Location', 'northeast');
hold off;