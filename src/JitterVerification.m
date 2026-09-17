% =========================================================================
% STANDALONE SCRIPT: ADCS Jitter Limit vs. TDI Stages
% =========================================================================
clear;
clc;
close all;

% --- MISSION PARAMETERS ---
velocity_vleo = 7720;       % Orbital velocity (m/s)
alt_vleo = 330.5 * 1000;    % Altitude (meters)
GSD = 1;                    % Ground Sample Distance (meters)
smear_budget = 0.10;        % Allowable drift (10% of a pixel)

% --- PHYSICS CALCULATIONS ---
% Maximum physical drift allowed on the ground
driftLimit_m = GSD * smear_budget;

% Convert ground drift into angular drift from the satellite's perspective
angularDrift_rad = driftLimit_m / alt_vleo;
angularDrift_deg = rad2deg(angularDrift_rad);

% Time it takes the satellite to fly over one 1-meter pixel
timePerStage = GSD / velocity_vleo;

% Create an array of TDI stages to evaluate (1 to 128 stages)
tdiArray = 1:128;

% Calculate the maximum allowable jitter for each stage
jitterLimitArray = angularDrift_deg ./ (tdiArray .* timePerStage);

% --- PLOTTING ---
figure('Name', 'ADCS Jitter Limit vs TDI Stages', 'Color', 'w', 'Position', [200, 200, 900, 550]);
plot(tdiArray, jitterLimitArray, 'LineWidth', 3, 'Color', '#0072BD');
hold on;

% Add the baseline capability for typical commercial Star Trackers
yline(0.002, 'k--', 'LineWidth', 2, 'DisplayName', 'Typical COTS Star Tracker Limit (0.002 deg/s)');

% 1. Highlight the 4-Stage Option (Low ADCS Risk)
idx4 = find(tdiArray == 4);
plot(4, jitterLimitArray(idx4), 'o', 'MarkerSize', 8, 'MarkerFaceColor', '#D95319', 'MarkerEdgeColor', 'k');
text(6, jitterLimitArray(idx4), sprintf('4 Stages: %.4f deg/s (Low ADCS Risk)', jitterLimitArray(idx4)), 'Color', '#D95319', 'FontWeight', 'bold');

% 2. Highlight our NEW 8-Stage Baseline (The Optimal Floor)
idx8 = find(tdiArray == 8);
plot(8, jitterLimitArray(idx8), 'o', 'MarkerSize', 10, 'MarkerFaceColor', '#77AC30', 'MarkerEdgeColor', 'k');
text(10, jitterLimitArray(idx8) + 0.001, sprintf('8 Stages: %.4f deg/s (Our Baseline)', jitterLimitArray(idx8)), 'Color', '#77AC30', 'FontWeight', 'bold');

% 3. Highlight the 64-Stage Option (High ADCS Risk)
idx64 = find(tdiArray == 64);
plot(64, jitterLimitArray(idx64), 'o', 'MarkerSize', 8, 'MarkerFaceColor', '#7E2F8E', 'MarkerEdgeColor', 'k');
text(66, jitterLimitArray(idx64) + 0.001, sprintf('64 Stages: %.4f deg/s (High ADCS Risk)', jitterLimitArray(idx64)), 'Color', '#7E2F8E', 'FontWeight', 'bold');

hold off;
grid on;
title('Maximum Allowable Spacecraft Jitter vs. TDI Stages (330.5 km, 7720 m/s)', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('Number of TDI Stages', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Maximum Allowable Jitter (degrees / sec)', 'FontSize', 11, 'FontWeight', 'bold');
legend('Jitter Tolerance Limit', 'COTS Hardware Capability', 'Location', 'northeast');

% Cap the axes to keep the graph readable
ylim([0, 0.04]);
xlim([0, 130]);