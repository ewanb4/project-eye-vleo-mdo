% Trade Space Tool (PHASE 1)

close all;
clear;
clc;

% Import Constants
trade_constants

[validOrbits, altArray] = findValidAltitudes(MIN_ALT, MAX_ALT, EARTH_GRAV_PARAM, EARTH_RADIUS, TAU_E, TAU_ES);

% Calculate the exact "Orbits per Day" ratio
orbitsPerDay = validOrbits(:, 2) ./ validOrbits(:, 1);

%altStepSize = 10; % (km)
%altArray = MIN_ALT:altStepSize:MAX_ALT; % (km)
altArrayLen = length(altArray);

figure('Name', 'RGT Altitude Trade Space', 'Color', 'w');
hold on;
% 1. Plot ALL orbits as standard blue dots (These are now the "Invalid" m > 5 ones)
scatter(orbitsPerDay, validOrbits(:, 3), 20, 'filled', 'MarkerFaceColor', '#0072BD', 'MarkerEdgeColor', 'k');
% 2. Draw the hard Cutoff Boundary Lines
yline(MAX_ALT, 'r--', 'Max Altitude (600 km)', 'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
yline(MIN_ALT, 'r--', 'Min Altitude (200 km)', 'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
% 3. Find and Highlight ALL valid targets (m <= 5) in bright orange
valid_m_indices = find(validOrbits(:, 1) <= 5);
scatter(orbitsPerDay(valid_m_indices), validOrbits(valid_m_indices, 3), 60, 'filled', 'MarkerFaceColor', '#D95319', 'MarkerEdgeColor', 'k');
% Formatting the graph
grid on;
box on;
xlabel('Orbits per Day (n / m)');
ylabel('Altitude (km)');
title('Valid SSO Repeating Ground Track Altitudes (Revisit \leq 5 Days)');
legend('Invalid Revisit (m > 5)', '600km VLEO Ceiling', '200km VLEO Floor', 'Valid Revisit (m \leq 5)', 'Location', 'northeast');
% Set the Y-axis limits slightly outside the bounds so we can clearly see the cutoffs
ylim([MIN_ALT - 50, MAX_ALT + 50]);
hold off;

% Extract only the rows where column 1 (m) is less than or equal to 5
validOrbitFiltered = validOrbits(validOrbits(:, 1) <= 5, :);
% Extract just the altitude column to pass into your optical loop
altArray = unique(validOrbitFiltered(:, 3)');
altArrayLen = length(altArray);


for i = 1:altArrayLen
    currentAlt = altArray(i);

    [inclinationDeg(i), velocity(i), orbitPeriod(i)] = orbitCalculator(currentAlt,EARTH_GRAV_PARAM,J2_CONSTANT,EARTH_RADIUS,PRECESSION_RATE);

    slantRange(i) = slantRangeCalculator(currentAlt, MAX_OFF_NADIR,EARTH_RADIUS);

    orbitPeriodMin(i) = orbitPeriod(i) / 60;
    
    % Maximum Eclipse Time Estimation based on Beta Angle = 0
    eclipseFrac = 1/pi * asin(EARTH_RADIUS / (EARTH_RADIUS + currentAlt));
    eclipseTimeSec(i) = eclipseFrac * orbitPeriod(i);
    eclipseTimeMin(i) = eclipseTimeSec(i) / 60;

% --- SR2 COVERAGE VERIFICATION ---
    % Find the exact row match for this altitude
    matchIndex = find(validOrbitFiltered(:,3) == currentAlt, 1);
    currentM = validOrbitFiltered(matchIndex, 1);
    currentN = validOrbitFiltered(matchIndex, 2);
    
    % CRITICAL BUG FIX: Force the fraction to simplify.
    % A 1-day orbit (15 orbits/1 day) will show up as 75 orbits/5 days.
    % Dividing by the GCD ensures we only count UNIQUE ground tracks.
    uniqueTracks = currentN / gcd(currentN, currentM);
    
    [trackGap(i), fieldOfRegard(i), sr2Compliant(i)] = verifyCoverage(currentAlt, uniqueTracks, TARGET_LAT, MAX_OFF_NADIR, EARTH_RADIUS);

    if ~isnan(slantRange(i))
        [FirstApertureDiameter(i), ~, rayleighMass(i)] = opticalPayloadCalculator(slantRange(i), WAVELENGTH_LIGHT, GSD);

        [apertureDiameter(i), focalLengthMin(i), focalLengthMax(i), snr(i), otaMass(i), pixelPitchMin(i), pixelPitchMax(i)] = optimisePayload(FirstApertureDiameter(i), slantRange(i), velocity(i), GSD, WAVELENGTH_LIGHT);

        telescopeLen(i) = 2 * apertureDiameter(i);
    else
        apertureDiameter(i) = NaN;
        telescopeLen(i) = NaN;
        otaMass(i) = NaN;
        FirstApertureDiameter(i) = NaN;
        focalLengthMin(i) = NaN;
        focalLengthMax(i) = NaN;
        pixelPitchMin(i) = NaN;
        pixelPitchMax(i) = NaN;
        snr(i) = NaN;

    end
end

% --- The Mass Multiplier ---
% Structure (20%) + Subsystems (25%) = 45%. 
% Therefore OTA + Power + Prop = 55% of total dry mass.
minDryMass = otaMass / 0.55;

disp("Generated Trade Space")

figure('Name', 'Mass Boundaries Trade Space', 'Color', 'w');
plot(altArray, otaMass, 'LineWidth', 2, 'Color', '#D95319');
hold on; % Tells MATLAB to draw the next line on the same graph
plot(altArray, rayleighMass, 'LineWidth', 2, 'Color', 'b');
%plot(altArray, minDryMass, 'LineWidth', 2, 'Color', '#0072BD', 'LineStyle', '--');
hold off;
grid on;
legend('OTA Mass Actual (Enlarged Aperture)','OTA Mass (TDI)', 'Location', 'northwest');
title('Satellite Mass Boundaries vs. Altitude');
xlabel('Altitude (km)');
ylabel('Mass (kg)');
xlim([min(altArray) max(altArray)]);

figure('Name', 'Optical Physics Drivers', 'Color', 'w');
yyaxis left
plot(altArray, slantRange,"-x",'MarkerSize',7,'MarkerEdgeColor','k' , 'LineWidth', 2);
ylabel('Maximum Slant Range (km)');
yyaxis right
plot(altArray, apertureDiameter,"-x",'MarkerSize',7,'MarkerEdgeColor','k' , 'LineWidth', 2);
ylabel('Required Aperture Diameter (m)');
grid on;
title('Slant Range & Aperture Sizing for 1m GSD');
xlabel('Altitude (km)');
xlim([min(altArray) max(altArray)]);

figure('Name', 'Orbital Environment', 'Color', 'w');
plot(altArray, inclinationDeg,"-x",'MarkerSize',7,'MarkerEdgeColor','k' , 'LineWidth', 2, 'Color', '#7E2F8E');
grid on;
title('Required SSO Inclination vs. Altitude');
xlabel('Altitude (km)');
ylabel('Inclination (Degrees)');
xlim([min(altArray) max(altArray)]);

figure('Name', 'Mission Timing', 'Color', 'w');
plot(altArray, orbitPeriodMin,"-x",'MarkerSize',7,'MarkerEdgeColor','r' , 'LineWidth', 2, 'Color', '#77AC30');
hold on;
plot(altArray, eclipseTimeMin,"-x",'MarkerSize',7,'MarkerEdgeColor','r' , 'LineWidth', 2, 'Color', '#000000', 'LineStyle', '-.');
hold off;
grid on;
legend('Total Orbital Period', 'Maximum Eclipse Duration', 'Location', 'east');
title('Orbital & Eclipse Timing vs. Altitude');
xlabel('Altitude (km)');
ylabel('Time (Minutes)');
xlim([min(altArray) max(altArray)]);

% Plot 5: Sensor Procurement Envelope
figure('Name', 'Sensor Procurement Envelope', 'Color', 'w');
hold on;
X_polygon = [altArray, fliplr(altArray)];
Y_polygon = [pixelPitchMax, fliplr(pixelPitchMin)];
fill(X_polygon, Y_polygon, [0, 0.4470, 0.7410], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
plot(altArray, pixelPitchMin, 'LineWidth', 2, 'Color', '#0072BD');
plot(altArray, pixelPitchMax, 'LineWidth', 2, 'Color', '#0072BD');
grid on;
title('Valid Sensor Pixel Size Envelope vs. Altitude');
xlabel('Altitude (km)');
ylabel('Required Pixel Pitch (\mum)');
legend('Valid Procurement Space', 'f = 6D & 30D Boundaries', 'Location', 'northwest');
xlim([min(altArray) max(altArray)]);
hold off;

figure('Name', 'Physical Bus Constraints', 'Color', 'w');
yyaxis left
plot(altArray, apertureDiameter,"-x",'MarkerSize',7,'MarkerEdgeColor','b', 'LineWidth', 2, 'Color', '#0072BD');
ylabel('Minimum Bus Width/Diameter (m)');
yyaxis right
plot(altArray, telescopeLen,"-x",'MarkerSize',7,'MarkerEdgeColor','b' ,'LineWidth', 2, 'Color', '#D95319');
ylabel('Minimum Bus Length (m)');
grid on;
title('Physical Spacecraft Dimensions vs. Altitude');
xlabel('Altitude (km)');
xlim([min(altArray) max(altArray)]);

figure('Name', 'SNR Convergence Verification', 'Color', 'w');
plot(altArray, snr, 'LineWidth', 2, 'Color', '#77AC30');
hold on;
yline(100, 'k--', 'Requirement Floor (SNR = 100)', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');
hold off;
grid on;
title('Optimiser Convergence Verification: Final SNR vs. Altitude');
xlabel('Altitude (km)');
ylabel('Optimised SNR');
% Zoom in the Y-axis to show the microscopic 1mm step variations
ylim([99.5 101.5]); 
xlim([min(altArray) max(altArray)]);

% =========================================================================
% --- GRAPH 8: SR2 COVERAGE VERIFICATION (HYBRID PILLARS) ---
% =========================================================================
figure('Name', 'SR2 Coverage Verification', 'Color', 'w', 'Position', [150, 150, 1000, 500]);
hold on; grid on;

% Define Native RGB Colors
color_blue  = [0.000, 0.447, 0.741]; % Capability (Field of Regard)
color_grey  = [0.250, 0.250, 0.250]; % Threat (Track Gap)
color_green = [0.466, 0.674, 0.188]; % Compliant
color_red   = [0.850, 0.325, 0.098]; % Failure

% 1. Plot the continuous capability ceiling (The smooth geometric baseline)
% We filter for valid points to ensure the line draws cleanly across the nodes
valid_idx = ~isnan(fieldOfRegard) & ~isnan(trackGap);
plot(altArray(valid_idx), fieldOfRegard(valid_idx), '-', 'Color', color_blue, 'LineWidth', 2, 'HandleVisibility', 'off');

% 2. Loop through exactly valid discrete nodes ONLY
for i = 1:length(altArray)
    x = altArray(i);
    y_cap = fieldOfRegard(i);
    y_req = trackGap(i);
    
    % Safety check: Skip invalid points
    if isnan(y_cap) || isnan(y_req)
        continue;
    end
    
    % Check Compliance to color the vertical pillar
    if y_cap >= y_req
        line_color = color_green;
    else
        line_color = color_red;
    end
    
    % Draw the vertical pillar (connecting capability to requirement)
    plot([x, x], [y_req, y_cap], '-', 'Color', line_color, 'LineWidth', 5, 'HandleVisibility', 'off');
    
    % Plot the discrete markers on the pillar
    % Blue Circle for our Capability
    scatter(x, y_cap, 150, 'o', 'MarkerFaceColor', color_blue, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    % Dark Grey Square for the Track Gap Threat
    scatter(x, y_req, 150, 's', 'MarkerFaceColor', color_grey, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
end

% 3. Create Dummy Plots for a Clean Legend
plot(NaN, NaN, '-o', 'Color', color_blue, 'MarkerFaceColor', color_blue, 'MarkerEdgeColor', 'k', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Capability: Optical Field of Regard');
plot(NaN, NaN, 's', 'MarkerFaceColor', color_grey, 'MarkerEdgeColor', 'k', 'MarkerSize', 10, 'DisplayName', 'Threat: Physical Track Gap');
plot(NaN, NaN, '-', 'Color', color_green, 'LineWidth', 4, 'DisplayName', 'Compliant Architecture');
plot(NaN, NaN, '-', 'Color', color_red, 'LineWidth', 4, 'DisplayName', 'Coverage Failure');

% 4. Presentation Formatting
title('SR2 Compliance: Discrete Orbital Nodes (40^{\circ} Lat)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Orbital Altitude (km)', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Distance on Ground (km)', 'FontSize', 16, 'FontWeight', 'bold');

set(gca, 'FontSize', 14, 'FontWeight', 'bold', 'Layer', 'top');
legend('Location', 'northwest', 'FontSize', 12);
xlim([min(altArray) - 10, max(altArray) + 10]); % Add a small buffer to the edges
hold off;

% =========================================================================
% --- ADVANCED SENSITIVITY ANALYSIS: HEATMAP ---
% =========================================================================
disp("Generating Mass Sensitivity Heatmap...");

% 1. Define the parameters to sweep
% We use your existing altArray (X-axis)
gsd_sweep = 0.5:0.05:2.0; % Sweep GSD from 0.5m (ultra-high) to 2.0m (Y-axis)

% Preallocate a 2D matrix for the heatmap (Rows = GSD, Cols = Altitude)
mass_heatmap = zeros(length(gsd_sweep), length(altArray));

% 2. Nested loop to calculate Payload Mass for every single combination
for i = 1:length(altArray)
    currentAlt = altArray(i);
    % Recalculate Slant Range for this altitude
    sRange = slantRangeCalculator(currentAlt, MAX_OFF_NADIR, EARTH_RADIUS);
    
    for j = 1:length(gsd_sweep)
        currentGSD = gsd_sweep(j);
        
        % Run your existing payload calculators with the sweeping GSD
        [FirstAp, ~, ~] = opticalPayloadCalculator(sRange, WAVELENGTH_LIGHT, currentGSD);
        [~, ~, ~, ~, currentMass, ~, ~] = optimisePayload(FirstAp, sRange, velocity(i), currentGSD, WAVELENGTH_LIGHT);
        
        % Save the calculated mass into the 2D matrix
        mass_heatmap(j, i) = currentMass;
    end
end

% 3. Plotting the Heatmap
figure('Name', 'Sensitivity Analysis: Mass Heatmap', 'Color', 'w');
[X_GRID, Y_GRID] = meshgrid(altArray, gsd_sweep);

% Use surf with 'view(0,90)' to create a top-down 2D heatmap
surf(X_GRID, Y_GRID, mass_heatmap, 'EdgeColor', 'none'); 
view(0, 90); 

% Formatting for maximum professional impact
colormap('turbo'); % High-contrast, industry-standard color palette
c = colorbar;
c.Label.String = 'Optical Payload Mass (kg)';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';

grid on;
title('System Sensitivity: Payload Mass vs. Altitude and Resolution');
xlabel('Altitude (km)', 'FontWeight', 'bold');
ylabel('Ground Sample Distance - GSD (m)', 'FontWeight', 'bold');

% Draw a line showing your actual chosen baseline (1m GSD)
hold on;
yline(1.0, 'w--', 'Baseline Design (1m GSD)', 'LineWidth', 2, 'LabelHorizontalAlignment', 'center', 'Color', 'w');
hold off;
% =========================================================================

% =========================================================================
% --- SNR FEASIBILITY & APERTURE INFLATION HEATMAP (PERFECT MATCH) ---
% =========================================================================
disp("Generating SNR Feasibility Heatmap using Native Function...");

% 1. Dynamic Y-Axis Sweep: Automatically scales to fit your massive apertures
max_ap = max(apertureDiameter) + 0.2; 
ap_sweep = linspace(0.1, max_ap, 100); % Sweeping Y-axis with 100 data points

% Preallocate the 2D matrix
snr_heatmap = zeros(length(ap_sweep), length(altArray));

% 2. Nested loop: Calls your EXACT SNRCalculator function
for i = 1:length(altArray)
    for j = 1:length(ap_sweep)
        
        currentAp = ap_sweep(j);
        
        % Calling your native function guarantees 100% mathematical parity
        calculated_snr = SNRCalculator(currentAp, slantRange(i), velocity(i), GSD, WAVELENGTH_LIGHT);
        
        snr_heatmap(j, i) = calculated_snr; 
    end
end

% 3. Plotting the High-Fidelity Heatmap
figure('Name', 'Payload Sizing: SNR & Diffraction Boundaries', 'Color', 'w');

% pcolor creates a flat, clean 2D heatmap without 3D artifacts
[X_GRID, Y_GRID] = meshgrid(altArray, ap_sweep);
h = pcolor(X_GRID, Y_GRID, snr_heatmap);
set(h, 'EdgeColor', 'none', 'HandleVisibility', 'off'); 
shading interp; 

colormap('turbo'); 
c = colorbar;
c.Label.String = 'Calculated Signal-to-Noise Ratio (SNR)';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';

hold on;

% 4. Overlay the explicit SNR = 100 physical boundary line
[C, hContour] = contour(X_GRID, Y_GRID, snr_heatmap, [100 100], 'k-', 'LineWidth', 2, 'DisplayName', 'Hard SNR = 100 Threshold');

grid on;
title('Optical Trade Space: SNR Feasibility vs. Rayleigh Limit');
xlabel('Altitude (km)', 'FontWeight', 'bold');
ylabel('Aperture Diameter (m)', 'FontWeight', 'bold');

% 5. Overlay the Rayleigh and Optimized limits
plot(altArray, FirstApertureDiameter, 'w-', 'LineWidth', 3, 'DisplayName', 'Rayleigh Limit (1m GSD)');
plot(altArray, apertureDiameter, 'r--', 'LineWidth', 3, 'DisplayName', 'Optimized Aperture Requirement');

lgd = legend('Location', 'northwest');
lgd.Color = [0.15 0.15 0.15]; % Sleek dark gray background
lgd.TextColor = 'w'; % White text so everything pops
ylim([0.1 1.4]);
hold off;
% =========================================================================

% --- SR2 COMPLIANCE FILTERING ---
disp("Filtering Trade Space for SR2 Compliance...");

% Find the indices of all altitudes that passed the SR2 coverage check
validSR2Indices = find(sr2Compliant == 1);

% Overwrite all the Phase 2 transfer variables to only include valid altitudes
altArray = altArray(validSR2Indices);
velocity = velocity(validSR2Indices);
apertureDiameter = apertureDiameter(validSR2Indices);
eclipseTimeMin = eclipseTimeMin(validSR2Indices);
orbitPeriodMin = orbitPeriodMin(validSR2Indices);
otaMass = otaMass(validSR2Indices);

% Save the strictly compliant variables for Phase 2
save("tradeSpaceVariables.mat","altArray","velocity","apertureDiameter","eclipseTimeMin","orbitPeriodMin","otaMass")

disp("Filtered Trade Space variables saved successfully.");

% =========================================================================
% --- ADVANCED SENSITIVITY ANALYSIS: HEATMAP (SMOOTH FULL RANGE) ---
% =========================================================================
disp("Generating Smooth Mass Sensitivity Heatmap...");

% 1. Define high-density continuous sweeps (Ignoring the RGT gaps for the plot)
% 150 points for Altitude, 100 points for GSD creates a beautiful, HD grid
alt_sweep = linspace(min(altArray), max(altArray), 150); 
gsd_sweep = linspace(0.5, 2.0, 100); 

% Preallocate a 2D matrix for the heatmap (Rows = GSD, Cols = Altitude)
mass_heatmap = zeros(length(gsd_sweep), length(alt_sweep));

% 2. Nested loop to calculate actual Payload Mass for every single pixel
for i = 1:length(alt_sweep)
    currentAlt = alt_sweep(i);
    
    % We must calculate the continuous velocity and slant range for this specific pixel
    [~, currentVel, ~] = orbitCalculator(currentAlt, EARTH_GRAV_PARAM, J2_CONSTANT, EARTH_RADIUS, PRECESSION_RATE);
    sRange = slantRangeCalculator(currentAlt, MAX_OFF_NADIR, EARTH_RADIUS);
    
    for j = 1:length(gsd_sweep)
        currentGSD = gsd_sweep(j);
        
        % Run your existing optical physics calculators
        if ~isnan(sRange)
            [FirstAp, ~, ~] = opticalPayloadCalculator(sRange, WAVELENGTH_LIGHT, currentGSD);
            [~, ~, ~, ~, currentMass, ~, ~] = optimisePayload(FirstAp, sRange, currentVel, currentGSD, WAVELENGTH_LIGHT);
            mass_heatmap(j, i) = currentMass;
        else
            mass_heatmap(j, i) = NaN;
        end
    end
end

% 3. Plotting the High-Resolution Heatmap
figure('Name', 'Sensitivity Analysis: Mass Heatmap', 'Color', 'w');
[X_GRID, Y_GRID] = meshgrid(alt_sweep, gsd_sweep);

% pcolor with shading interp physically blends the colors without grid lines
pcolor(X_GRID, Y_GRID, mass_heatmap); 
shading interp; 

% Formatting for maximum professional impact
colormap('turbo'); % High-contrast, industry-standard color palette
c = colorbar;
c.Label.String = 'Optical Payload Mass (kg)';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';

grid on;
set(gca, 'Layer', 'top'); % Keeps grid lines cleanly visible over the heatmap

title('System Sensitivity: Payload Mass vs. Altitude and Resolution');
xlabel('Altitude (km)', 'FontWeight', 'bold');
ylabel('Ground Sample Distance - GSD (m)', 'FontWeight', 'bold');

% Draw a line showing your actual chosen baseline (1m GSD)
hold on;
yline(1.0, 'w--', 'Baseline Design (1m GSD)', 'LineWidth', 2, 'LabelHorizontalAlignment', 'center', 'Color', 'w');
hold off;
% =========================================================================

% =========================================================================
% --- SNR FEASIBILITY & APERTURE INFLATION HEATMAP (SMOOTH FULL RANGE) ---
% =========================================================================
disp("Generating Smooth SNR Feasibility Heatmap...");

% 1. Dynamic Axis Sweeps for High-Resolution Grid
max_ap = max(apertureDiameter) + 0.2; 
ap_sweep_dense = linspace(0.1, 1.4, 200); % 200 points for hyper-smooth Y-axis
alt_sweep_dense = linspace(min(altArray), max(altArray)+100, 200); % 200 points for continuous X-axis

% Preallocate the 2D matrix and the 1D smooth overlay arrays
snr_heatmap_smooth = zeros(length(ap_sweep_dense), length(alt_sweep_dense));
smooth_rayleigh = zeros(1, length(alt_sweep_dense));
smooth_optimized = zeros(1, length(alt_sweep_dense));

% 2. Nested loop: Calculate actual physics for every pixel
for i = 1:length(alt_sweep_dense)
    currentAlt = alt_sweep_dense(i);
    
    % Recalculate continuous velocity and slant range for this exact pixel
    [~, currentVel, ~] = orbitCalculator(currentAlt, EARTH_GRAV_PARAM, J2_CONSTANT, EARTH_RADIUS, PRECESSION_RATE);
    sRange = slantRangeCalculator(currentAlt, MAX_OFF_NADIR, EARTH_RADIUS);
    
    % Calculate the high-definition Rayleigh and Optimized limits for the overlay lines
    if ~isnan(sRange)
        [smooth_rayleigh(i), ~, ~] = opticalPayloadCalculator(sRange, WAVELENGTH_LIGHT, GSD);
        [smooth_optimized(i), ~, ~, ~, ~, ~, ~] = optimisePayload(smooth_rayleigh(i), sRange, currentVel, GSD, WAVELENGTH_LIGHT);
    else
        smooth_rayleigh(i) = NaN;
        smooth_optimized(i) = NaN;
    end
    
    % Calculate the SNR for the actual heatmap background
    for j = 1:length(ap_sweep_dense)
        currentAp = ap_sweep_dense(j);
        
        if ~isnan(sRange)
            calculated_snr = SNRCalculator(currentAp, sRange, currentVel, GSD, WAVELENGTH_LIGHT);
            snr_heatmap_smooth(j, i) = calculated_snr; 
        else
            snr_heatmap_smooth(j, i) = NaN;
        end
    end
end

% 3. Plotting the High-Fidelity Heatmap
figure('Name', 'Payload Sizing: SNR & Diffraction Boundaries', 'Color', 'w', 'Position', [250, 250, 900, 550]);
[X_GRID, Y_GRID] = meshgrid(alt_sweep_dense, ap_sweep_dense);

% pcolor combined with shading interp physically blends the colors
h = pcolor(X_GRID, Y_GRID, snr_heatmap_smooth);
set(h, 'EdgeColor', 'none', 'HandleVisibility', 'off'); 
shading interp; 

colormap('turbo'); 
c = colorbar;
c.Label.String = 'Calculated Signal-to-Noise Ratio (SNR)';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';

hold on;

% 4. Overlay the explicit SNR = 100 physical boundary contour
[~, hContour] = contour(X_GRID, Y_GRID, snr_heatmap_smooth, [100 100], 'k-', 'LineWidth', 3, 'DisplayName', 'Hard SNR = 100 Threshold');

% 5. Plot the fully smoothed Rayleigh and Optimized limit lines
plot(alt_sweep_dense, smooth_rayleigh, 'w-', 'LineWidth', 3, 'DisplayName', 'Rayleigh Limit (1m GSD)');
plot(alt_sweep_dense, smooth_optimized, 'r--', 'LineWidth', 3, 'DisplayName', 'Optimized Aperture Requirement');

grid on;
set(gca, 'Layer', 'top'); % Keeps grid lines cleanly visible over the heatmap

title('Optical Trade Space: SNR Feasibility vs. Rayleigh Limit', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Aperture Diameter (m)', 'FontSize', 12, 'FontWeight', 'bold');

lgd = legend('Location', 'northwest');
lgd.Color = [0.15 0.15 0.15]; % Sleek dark gray background
lgd.TextColor = 'w'; % White text so everything pops

ylim([0.1 1.4]);
xlim([min(altArray) max(altArray)+100]);
hold off;
% =========================================================================

% =========================================================================
% --- SLIDE 2: THE VLEO ATMOSPHERIC DENSITY WALL ---
% =========================================================================

% 1. Define Altitude Range (200 km to 800 km)
altRange = linspace(200, 800, 500);

% 2. Simplified Exponential Atmosphere Model for Visualization
% (Using standard reference values for LEO/VLEO transition)
rho_ref = 1.9e-11; % kg/m^3 at 300km
h_ref = 300;
scale_height = 55; % Approximate scale height in km
density = rho_ref .* exp(-(altRange - h_ref) ./ scale_height);

% 3. Initialize Figure
figure('Name', 'Slide 2: Density Wall', 'Color', 'w', 'Position', [150, 150, 800, 450]);
semilogy(altRange, density, 'k-', 'LineWidth', 3); % Logarithmic Y-Axis is critical here
hold on; grid on;

% 4. Fill the "VLEO Danger Zone" (Under 450 km)
vleo_alts = altRange(altRange <= 450);
vleo_dens = density(altRange <= 450);
area(vleo_alts, vleo_dens, 'FaceColor', '#D95319', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 5. Highlight Key Architectures
keyAlts = [330.5, 800];
labels = ["Our VLEO Baseline", "Standard LEO"];
markerColors = ["#77AC30", "#0072BD"];

for i = 1:length(keyAlts)
    h = keyAlts(i);
    % Calculate exact density at this point
    d_val = rho_ref * exp(-(h - h_ref) / scale_height);
    
    % Plot the scatter dot
    scatter(h, d_val, 150, 'MarkerFaceColor', markerColors(i), 'MarkerEdgeColor', 'k', 'LineWidth', 2);
    
    % Add text labels
    if i == 1
        text(h + 15, d_val, sprintf('%s (%.1f km)', labels(i), h), ...
            'FontSize', 12, 'FontWeight', 'bold', 'Color', markerColors(i), 'VerticalAlignment', 'bottom');
    else
        text(h - 15, d_val, sprintf('%s (%.0f km)', labels(i), h), ...
            'FontSize', 12, 'FontWeight', 'bold', 'Color', markerColors(i), 'HorizontalAlignment', 'right');
    end
end

% 6. Formatting
title('The Environmental Cost: Atmospheric Density vs. Altitude', 'FontSize', 16, 'FontWeight', 'bold');
xlabel('Orbital Altitude (km)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Atmospheric Density (kg/m^3) - Log Scale', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'bold');
xlim([200, 800]);
ylim([1e-15, 1e-9]); % Lock standard atmospheric bounds
hold off;

% =========================================================================
% --- SLIDE 2: THE VLEO ATMOSPHERIC DENSITY WALL ---
% =========================================================================

% 1. Define Altitude Range (200 km to 800 km)
altRange = linspace(200, 800, 500);

% 2. Simplified Exponential Atmosphere Model for Visualization
% (Using standard reference values for LEO/VLEO transition)
rho_ref = 1.9e-11; % kg/m^3 at 300km
h_ref = 300;
scale_height = 55; % Approximate scale height in km
density = rho_ref .* exp(-(altRange - h_ref) ./ scale_height);

% 3. Initialize Figure
figure('Name', 'Slide 2: Density Wall', 'Color', 'w', 'Position', [150, 150, 800, 450]);
semilogy(altRange, density, 'k-', 'LineWidth', 3); % Logarithmic Y-Axis is critical here
hold on; grid on;

% 4. Fill the "VLEO Danger Zone" (Under 450 km)
vleo_alts = altRange(altRange <= 450);
vleo_dens = density(altRange <= 450);
area(vleo_alts, vleo_dens, 'FaceColor', '#D95319', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 5. Highlight Key Architectures
keyAlts = [330.5, 800];
labels = ["Our VLEO Baseline", "Standard LEO"];
markerColors = ["#77AC30", "#0072BD"];

for i = 1:length(keyAlts)
    h = keyAlts(i);
    % Calculate exact density at this point
    d_val = rho_ref * exp(-(h - h_ref) / scale_height);
    
    % Plot the scatter dot
    scatter(h, d_val, 150, 'MarkerFaceColor', markerColors(i), 'MarkerEdgeColor', 'k', 'LineWidth', 2);
    
    % Add text labels
    if i == 1
        text(h + 15, d_val, sprintf('%s (%.1f km)', labels(i), h), ...
            'FontSize', 12, 'FontWeight', 'bold', 'Color', markerColors(i), 'VerticalAlignment', 'bottom');
    else
        text(h - 15, d_val, sprintf('%s (%.0f km)', labels(i), h), ...
            'FontSize', 12, 'FontWeight', 'bold', 'Color', markerColors(i), 'HorizontalAlignment', 'right');
    end
end

% 6. Formatting
title('The Environmental Cost: Atmospheric Density vs. Altitude', 'FontSize', 16, 'FontWeight', 'bold');
xlabel('Orbital Altitude (km)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Atmospheric Density (kg/m^3) - Log Scale', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'bold');
xlim([200, 800]);
ylim([1e-15, 1e-9]); % Lock standard atmospheric bounds
hold off;

% =========================================================================
% --- SLIDE 2: THE NEW GSD vs. ALTITUDE TRADE SPACE HEATMAP ---
% =========================================================================

% 1. Create the Trade Space Grid
altGrid = linspace(10, 40000, 500); % Orbital Altitude (km)
gsdGrid = linspace(0.1, 5, 500);    % Ground Sample Distance (m)
[AltSpace, GsdSpace] = meshgrid(altGrid, gsdGrid);

% 2. Calculate the Required Aperture and Payload Mass for the grid
DiamSpace = AltSpace ./ (1000 .* GsdSpace);
MassSpace = 146 .* (DiamSpace .^ 1.27);

% 3. Initialize the Figure
figure('Name', 'Slide 2: GSD Trade Space', 'Color', 'w', 'Position', [150, 150, 1100, 600]);
hold on;

% 4. Plot the Heatmap
imagesc(altGrid, gsdGrid, MassSpace);
set(gca, 'YDir', 'normal'); 

% 5. Apply the Logarithmic Color Scale
set(gca, 'ColorScale', 'log'); 
colormap(turbo);
c = colorbar;
c.FontSize = 14;
c.Label.String = 'Optical Payload Mass (kg) - Log Scale';
c.Label.FontSize = 16;
c.Label.FontWeight = 'bold';

% 6. Overlay the 1-meter GSD Mission Requirement Line
plot([0, 40000], [1.0, 1.0], 'w--', 'LineWidth', 3);

% 7. Define the Key Architectures
keyAlts = [330.5, 800, 20000, 35786];
labels = ["Our VLEO Baseline", "Standard LEO", "MEO / GPS", "GEO"];

% 8. Plot the specific architecture points along the Y=1.0 line
for i = 1:length(keyAlts)
    h = keyAlts(i);
    m = 146 * ((h / 1000) ^ 1.27); % Mass at GSD = 1.0
    
    % Plot the scatter dot strictly on the 1.0m line
    scatter(h, 1.0, 250, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 2);
    
    % Dynamic Label Placement (Alternating Up/Down to avoid horizontal collisions)
    if i == 1 % VLEO Baseline
        t_x = h + 600; t_y = 0.85; 
        hAlign = 'left'; vAlign = 'top';
    elseif i == 2 % Standard LEO
        t_x = h + 200; t_y = 1.15; 
        hAlign = 'left'; vAlign = 'bottom';
    elseif i == 3 % MEO / GPS
        t_x = h; t_y = 0.85; 
        hAlign = 'center'; vAlign = 'top';
    elseif i == 4 % GEO
        t_x = h - 1000; t_y = 1.15; 
        hAlign = 'right'; vAlign = 'bottom';
    end
    
    % Add readable data labels
    text(t_x, t_y, sprintf(' %s \n Mass: %.0f kg ', labels(i), m), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w', ...
        'BackgroundColor', [0 0 0 0.6], 'EdgeColor', 'w', 'Margin', 2, ...
        'HorizontalAlignment', hAlign, 'VerticalAlignment', vAlign);
end

% 9. Set Tick Mark Sizes FIRST
set(gca, 'FontSize', 14, 'FontWeight', 'bold');

% 10. Set Final Title and Axis Labels (Massive for the slide)
title('Payload Trade Space: Mass vs. Altitude and Resolution (GSD)', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Orbital Altitude (km)', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Ground Sample Distance (m) [Lower is Better]', 'FontSize', 16, 'FontWeight', 'bold');

% Frame the graph
xlim([0, 38000]);
ylim([0, 5]); % Lock the view between 0 and 5 meters resolution
grid on;
set(gca, 'Layer', 'top');
hold off;

% =========================================================================
% --- SLIDE 2: THE VLEO ATMOSPHERIC DENSITY WALL (REVISED) ---
% =========================================================================

% 1. Define Extended Altitude Range (200 km to 1500 km)
altRange = linspace(200, 1500, 1000);

% 2. Simplified Exponential Atmosphere Model for Conceptual Visualization
rho_ref = 1.9e-11; % kg/m^3 at 300km
h_ref = 300;
scale_height = 55; % Conceptual scale height for visual curve
density = rho_ref .* exp(-(altRange - h_ref) ./ scale_height);

% 3. Initialize Figure
figure('Name', 'Slide 2: Density Wall', 'Color', 'w', 'Position', [150, 150, 900, 500]);
semilogy(altRange, density, 'k-', 'LineWidth', 3);
hold on; grid on;

% 4. Fill the "VLEO Regime" Danger Zone (Everything under 450 km)
vleo_alts = altRange(altRange <= 450);
vleo_dens = density(altRange <= 450);
area(vleo_alts, vleo_dens, 'FaceColor', '#D95319', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 5. Add a clean, authoritative label for the VLEO region
% We place it safely inside the shaded zone with a semi-transparent background
text(325, 1e-11, 'VLEO Regime (< 450 km)', 'FontSize', 16, 'FontWeight', 'bold', ...
     'Color', '#D95319', 'HorizontalAlignment', 'center', ...
     'BackgroundColor', [1 1 1 0.8], 'EdgeColor', '#D95319', 'Margin', 3);

% 6. Set Tick Mark Sizes FIRST (Order of Operations)
set(gca, 'FontSize', 14, 'FontWeight', 'bold');

% 7. Final Formatting for the Presentation Slide
title('The Environmental Cost: Atmospheric Density vs. Altitude', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Orbital Altitude (km)', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Atmospheric Density (kg/m^3) - Log Scale', 'FontSize', 16, 'FontWeight', 'bold');

% Frame the graph perfectly to emphasize the drop
xlim([200, 1500]);
ylim([1e-21, 1e-9]); % Dropping the Y-axis floor shows the massive vacuum at 1500km
set(gca, 'Layer', 'top'); % Keeps grid lines visible over the shading
hold off;

% =========================================================================
% --- SLIDE 3: REVISIT TIME VS ALTITUDE (CLEAN PHASE 1 DATA) ---
% =========================================================================
% This hooks directly into your existing validOrbitFiltered matrix
% Column 1 = 'm' (Days to Revisit), Column 2 = 'n' (Total Orbits), Column 3 = Altitude (km)

% 1. Extract the raw data
raw_days = validOrbitFiltered(:, 1);
raw_orbits = validOrbitFiltered(:, 2);
raw_alts = validOrbitFiltered(:, 3);

% 2. Filter for strictly UNIQUE ground tracks (Irreducible Fractions)
% This prevents a 1-day revisit from also being plotted as a 2-day or 3-day revisit
unique_idx = gcd(raw_orbits, raw_days) == 1;

slide3_days = raw_days(unique_idx);
slide3_alts = raw_alts(unique_idx);

% 3. Initialize Figure
figure('Name', 'Slide 3: Revisit Time Trade Space', 'Color', 'w', 'Position', [150, 150, 1000, 600]);
hold on; grid on;

% 4. Plot all valid, unique operational nodes
scatter(slide3_alts, slide3_days, 150, 'MarkerFaceColor', '#0072BD', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

% 5. Presentation Formatting
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
title('Valid Sun-Synchronous Altitudes by Exact Revisit Time', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Orbital Altitude (km)', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Fundamental Revisit Time (Days)', 'FontSize', 16, 'FontWeight', 'bold');

% Lock Y-axis to discrete integer days
yticks(1:5);
ylim([0.5, 5.5]);

% Match the X-axis limits to your Phase 1 MAX_ALT/MIN_ALT constraints
xlim([MIN_ALT, MAX_ALT]); 

set(gca, 'Layer', 'top');
hold off;

