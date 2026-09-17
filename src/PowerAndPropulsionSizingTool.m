% Thruster Sizing Tool
clear;
clc;
close all;

trade_constants
load("tradeSpaceVariables.mat")
power_thruster_constants

% Grabs max CD values needed

load("largeAoaArray.mat","aoaArray")
load("cuboidV1SatCDArray.mat","cdArray")
cdArray1 = abs(cdArray);
load("cuboidV2SatCDArray.mat","cdArray")
cdArray2 = abs(cdArray);
load("circularSatCDArray.mat","cdArray")
cdArray3 = abs(cdArray);

maxCDOne = max(cdArray1);
maxCDTwo = max(cdArray2);
maxCDThree = max(cdArray3);

cuboidCDDeployed = maxCDTwo;
cylindricalCDFace = maxCDThree;

% CD OVERRIDE
cuboidCDDeployed = 2.45;
cuboidCDFace = 2.38;
cylindericalCDDeployed = 2.275;
cylindricalCDFace = 2.2;
hexCDDeployed = 2.36;

% --- ORBITAL GEOMETRY CONSTANTS ---
% Max Beta Angle for 10:30 LTAN SSO (Degrees)
MAX_BETA_ANGLE = 0; 

% Lambert's Cosine Law Efficiency Factor
BETA_EFFICIENCY = cosd(MAX_BETA_ANGLE); % Outputs ~0.819


cdArray = [cuboidCDDeployed,cylindricalCDFace,cuboidCDFace,cylindericalCDDeployed,hexCDDeployed];

% Thruster Options [ISP. Input Power, Efficiency]
resistoJet = [300,0.75 * 1000,((90+65)/2) / 100];
arcJet = [550,1.55 * 1000, 35 / 100];
ionThruster = [3050,2.35 * 1000, 60 / 100];
hallThruster = [1750, 3 * 1000, (35 + 60)/2 / 100];
ppt = [1075, 0.2 * 1000, 10 / 100];

ispArray = [resistoJet(1),arcJet(1),ionThruster(1),hallThruster(1),ppt(1)];
efficiencyArray = [resistoJet(3),arcJet(3),ionThruster(3),hallThruster(3),ppt(3)];

% MAIN LOOP

% ---  APPLYING MARGINS ---
DRY_MASS_MARGIN = 1.20; % +20% Mass Growth Allowance
PROP_MARGIN = 1.1;     % +10% Trapped/Residual Fuel Allowance
POWER_MARGIN = 1.2; % 20% Margin for Power Requirement
BATTERY_CAPACITY_MARGIN = 1.2; % 20% Margin for Real-World COTS Procurement
BUS_CLEARANCE = 0.10; % Clearnace in m, for vibrations + patch

for g = 1:length(cdArray)
    currentCD = cdArray(g);

    for t = 1:length(ispArray)
        Isp = ispArray(t);
        etaT = efficiencyArray(t);

        for i = 1:length(altArray)
            currentAlt = altArray(i);
            currentVel = velocity(i) * 1000;
            currentDiameter = apertureDiameter(i);

         % --- DYNAMIC GEOMETRY & POWER CONVERGENCE LOOP ---
            % Industry Standard: 3-panel Z-fold on 2 wings (Port/Starboard) = 6 panels total
            Z_FOLD_STAGES = 3; 
            NUM_WINGS = 2; 
            MAX_PANELS = Z_FOLD_STAGES * NUM_WINGS; 
            
            % 1. LOCK THE WIDTH (Nadir Deck Constraints)
            fixedWidthFaceted = currentDiameter + 0.10; 
            fixedWidthCylinder = currentDiameter + 0.20; 
  

            % --- DYNAMIC HEXAGON INFLATION (20% VOLUME FIX) ---
            if g == 5 % Apply strictly to the Hexagon configuration
                keepOutRadius = (currentDiameter / 2) + 0.05; % 5cm radial clearance
                keepOutArea = pi * (keepOutRadius^2);
                
                % Force the total bus area to be large enough that keep-out is only 80%
                reqHexArea = keepOutArea / 0.80; 
                
                % Calculate the new Flat-to-Flat width required for this area
                inflatedHexWidth = sqrt((reqHexArea * 2) / sqrt(3));
                
                % Override the baseline width with the inflated width
                fixedWidthFaceted = max(fixedWidthFaceted, inflatedHexWidth);
                disp( currentAlt)
                disp( Isp)
                disp(fixedWidthFaceted)
            end
            % -------------------------------------------------------
            
            % 2. MINIMUM LENGTH (Dictated by the Optics)
            % The coursework brief states the telescope length is twice the aperture [cite: 75]
            minChassisLength = 2 * currentDiameter;

            % Initialize the convergence loop
            [~, rhoData] = atmosnrlmsise00(currentAlt * 1000, 0, 0, 2026, 1, 0, 'None');
            rho = rhoData(6); % Total Mass Density (kg/m^3)
            solarArrayArea = 0.1; % Initial guess (m^2)
            tolerance = 0.001;
            error = 1;

            while error > tolerance
                oldSolarArrArea = solarArrayArea;
                
                % 3. DYNAMIC LENGTH STRETCHING (The "Flashlight" Effect)
                % We must calculate the PHYSICAL silicon area needed before stretching
                
                if g == 1 || g == 4 || g == 5 % Deployed arrays track the sun 1:1
                    physicalSaArea = solarArrayArea;
                    reqPanelFootprint = physicalSaArea / 6; % 6-panel Z-fold cheat code
                    
                    reqLengthFaceted = reqPanelFootprint / fixedWidthFaceted;
                    reqLengthCylinder = reqPanelFootprint / fixedWidthCylinder;
                    
                elseif g == 3 % Cuboid Body-Mounted (Requires 2x silicon to guarantee sun exposure)
                    physicalSaArea = solarArrayArea * 2;
                    % Stretch the length to fit the physical silicon on 2 faces
                    reqLengthFaceted = physicalSaArea / (2 * fixedWidthFaceted);
                    reqLengthCylinder = minChassisLength; % Dummy variable
                    
                elseif g == 2 % Cylinder Body-Mounted (Requires pi * x silicon to wrap hull)
                    physicalSaArea = solarArrayArea * pi;
                    % Stretch the length to fit the physical silicon around the cylinder
                    reqLengthCylinder = physicalSaArea / (pi * fixedWidthCylinder);
                    reqLengthFaceted = minChassisLength; % Dummy variable
                end
                
                % The max() function ensures the bus never shrinks smaller than the telescope
                actualLengthFaceted = max(minChassisLength, reqLengthFaceted);
                actualLengthCylinder = max(minChassisLength, reqLengthCylinder);
                
                % 4. CALCULATE TRUE RAM AREA (Width * Length hitting the wind)
                ramAreaFaceted = fixedWidthFaceted * actualLengthFaceted;
                ramAreaCylinder = fixedWidthCylinder * actualLengthCylinder;
                
                % Map specific Ram Areas to the 5 configurations
                busRamAreaArray = [ramAreaFaceted, ramAreaCylinder, ramAreaFaceted, ramAreaCylinder, ramAreaFaceted];
                currentChassisRamArea = busRamAreaArray(g);
                
                % 5. AERODYNAMIC CROSS-SECTION LOGIC (A_ref)
                if g == 1 || g == 4 || g == 5 % Deployed Arrays catch the wind too
                    Aref = currentChassisRamArea + solarArrayArea;
                elseif g == 2 || g == 3 % Body-Mounted
                    Aref = currentChassisRamArea;
                end
                
                % 6. POWER & DRAG CASCADE
                dragForce = 0.5 * rho * currentVel^2 * currentCD * Aref;
                thrustPower = (dragForce * Isp * g0) / (2 * etaT);
                totalPower = thrustPower + BUS_POWER;
                
                eclipseRatio = eclipseTimeMin(i) / orbitPeriodMin(i);
                sunRatio = 1 - eclipseRatio;
                powerGenerationReq = (totalPower / sunRatio) * POWER_MARGIN;
                
                newSolarArrArea = powerGenerationReq / (SOLAR_CONST * SOLAR_EFF * ARRAY_PACKING_DENSITY * ((1 - SOLAR_ARRAY_DEG)^5) * BETA_EFFICIENCY);
                
                error = abs(newSolarArrArea - oldSolarArrArea);
                solarArrayArea = newSolarArrArea;
            end
            % ---------------------------------------------------------
            
            dragForceFinalArray(g,t,i) = dragForce;
            propMass = (dragForce * MISSION_DURATION) / (Isp * g0);
            energyEclipseWh = totalPower * (eclipseTimeMin(i) / 60);

            reqBattCapacityWh = (energyEclipseWh / BATTERY_DOD) * BATTERY_CAPACITY_MARGIN;
            
            % Calculate mass based on the REQUIRED capacity, not just the energy used
            battMass = reqBattCapacityWh / BATTERY_DENSITY;

           % solarArrayMass = solarArrayArea * SOLAR_MASS_PER_M2;

            % GEOMETRIC MASS PENALTY LOGIC
            if g == 1 || g == 4 || g == 5 % Deployed Arrays track the sun 1:1
                physicalSaArea = solarArrayArea; 
            elseif g == 2 % Cylinder Body-Mounted: curved surface penalty
                physicalSaArea = solarArrayArea * pi; 
            elseif g == 3 % Cuboid Body-Mounted: 2 usable faces due to thruster/payload packaging
                physicalSaArea = solarArrayArea * 2; 
            end
            
            % Calculate mass based on the PHYSICAL silicon printed, not the effective area
            solarArrayMass = physicalSaArea * SOLAR_MASS_PER_M2;

            baselineDryMass = (otaMass(i) + solarArrayMass + battMass) / 0.55; 
            baselinePropMass = propMass;

            finalDryMass = baselineDryMass * DRY_MASS_MARGIN;
            finalPropMass = baselinePropMass * PROP_MARGIN;

            % ---  FINAL WET MASS RECORDING ---
            wetMass(g, t, i) = finalDryMass + finalPropMass;
            propMassArray(g,t,i) = finalPropMass;
            solarArrayAreaFinal(g,t,i) = physicalSaArea;
            totalPowerFinal(g,t,i) = totalPower;
            ArefFinal(g, t, i) = Aref;
            reqBattCapacityWhFinal(g, t, i) = reqBattCapacityWh;

            % --- FINAL GEOMETRY RECORDING ---
            % (Put this right next to wetMass(g,t,i) = ...)
            finalWidthFaceted(g, t, i) = fixedWidthFaceted;
            finalLengthFaceted(g, t, i) = actualLengthFaceted;
            
            finalWidthCylinder(g, t, i) = fixedWidthCylinder;
            finalLengthCylinder(g, t, i) = actualLengthCylinder;
        end
    end
end

thrusterNames = ["Resistojet", "Arcjet", "Ion Thruster", "Hall Thruster", "PPT"];
% Colors: Purple, Orange, Blue, Yellow, Green
colors = ["#7E2F8E", "#D95319", "#0072BD", "#EDB120", "#77AC30"]; 

% --- Graph 1: Wet Mass (Cuboid) ---
figure('Name', 'Wet Mass vs Altitude: Cuboid', 'Color', 'w');
hold on;
for t = 1:5
    plot(altArray, squeeze(wetMass(1, t, :)),"-x",'MarkerSize',7,'MarkerEdgeColor','k' , 'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Total Wet Mass vs. Altitude (Cuboid Chassis - Deployed Arrays)');
xlabel('Altitude (km)');
ylabel('Total Wet Mass (kg)');
legend(thrusterNames, 'Location', 'northeast');
% Cap Y-axis so the Resistojet/PPT mass failures don't ruin the scale
ylim([0, 1000]);

% --- Graph 2: Wet Mass (Cylinder) ---
figure('Name', 'Wet Mass vs Altitude: Cylinder', 'Color', 'w');
hold on;
for t = 1:5
    plot(altArray, squeeze(wetMass(2, t, :)), "-x",'MarkerSize',7,'MarkerEdgeColor','k' ,'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Total Wet Mass vs. Altitude (Cylindrical Chassis)');
xlabel('Altitude (km)');
ylabel('Total Wet Mass (kg)');
legend(thrusterNames, 'Location', 'northeast');
% Cap Y-axis so the Resistojet/PPT mass failures don't ruin the scale
%ylim([0, max(squeeze(wetMass(2, 4, :))) * 1.5]); 

% --- Graph 3: The Geometric Advantage (Ion Thruster Baseline) ---
% Compares the Cuboid vs Cylinder Solar Array size for the Ion Thruster (t=3)
figure('Name', 'Solar Array Area: Cuboid vs Cylinder', 'Color', 'w');
plot(altArray, squeeze(solarArrayAreaFinal(1, 3, :)), 'LineWidth', 2, 'Color', '#D95319', 'LineStyle', '--');
hold on;
plot(altArray, squeeze(solarArrayAreaFinal(2, 3, :)), 'LineWidth', 2, 'Color', '#0072BD');
hold off;
grid on;
title('Required Solar Array Area vs. Altitude (Ion Thruster)');
xlabel('Altitude (km)');
ylabel('Solar Array Area (m^2)');
legend('Cuboid (Deployed Wings)', 'Cylinder (Body-Mounted)', 'Location', 'northeast');       
ylim([0, 15])

% FIGURE 4
figure('Name', 'Solar Array Area vs Altitude: Cylinder', 'Color', 'w');
hold on;
for t = 1:5
    % g = 2 pulls the data specifically for the Cylindrical chassis
    plot(altArray, squeeze(solarArrayAreaFinal(2, t, :)), "-x",'MarkerSize',7,'MarkerEdgeColor','k' ,'LineWidth', 2, 'Color', colors(t));
end
% Calculate the max effective area (busArea) for all altitudes
% NEW DYNAMIC LIMIT: Cylinder Body-Mounted (g=2)
% Limit = Pi * Width * Length (Surface area of the cylinder wall)
maxAreaLimit = pi .* squeeze(finalWidthCylinder(2, 3, :)) .* squeeze(finalLengthCylinder(2, 3, :));

plot(altArray, maxAreaLimit, 'k--', 'LineWidth', 2, 'DisplayName', 'Absolute Physical Area Limit');
hold off;
grid on;
title('Required Solar Array Area vs. Altitude (Cylindrical Chassis)');
xlabel('Altitude (km)');
ylabel('Total Solar Array Area (m^2)');
legend(thrusterNames, 'Location', 'northeast');

% Cap Y-axis so the PPT/Resistojet death spirals don't ruin the scale
% We limit the graph to 1.5x the highest area demanded by the Hall Thruster
%ylim([0, max(squeeze(solarArrayAreaFinal(2, 4, :))) * 1.5]);

% --- Graph 5: Solar Array Area (Cuboid Chassis - Deployed Arrays) ---
figure('Name', 'Solar Array Area vs Altitude: Cuboid', 'Color', 'w');
hold on;
for t = 1:5
    % g = 1 pulls the data specifically for the Cuboid chassis
    plot(altArray, squeeze(solarArrayAreaFinal(1, t, :)), "-x",'MarkerSize',7,'MarkerEdgeColor','k' ,'LineWidth', 2, 'Color', colors(t));
end

% 6 Panels Total (3-panel Z-fold on 2 deployed wings)
% Stowage Limit = 6 * (Width * Length)
cuboidMaxAreaLimit = 6 .* squeeze(finalWidthFaceted(1, 3, :)) .* squeeze(finalLengthFaceted(1, 3, :));

plot(altArray, cuboidMaxAreaLimit, 'k--', 'LineWidth', 2, 'DisplayName', 'Absolute Stowage Limit (6-Panel Z-Fold)');

% Plot the limit as a thick dashed black line
plot(altArray, cuboidMaxAreaLimit, 'k--', 'LineWidth', 2, 'DisplayName', 'Absolute Stowage Limit');

hold off;
grid on;
title('Required Solar Array Area vs. Altitude (Cuboid Chassis - Deployed Arrays)');
xlabel('Altitude (km)');
ylabel('Total Solar Array Area (m^2)');
legend([thrusterNames, "Absolute Stowage Limit"], 'Location', 'northeast');

% Cap Y-axis so the PPT/Resistojet death spirals don't ruin the scale
ylim([0, 15]);

% --- Graph 6: Total Power Requirement vs Altitude (Cuboid) ---
figure('Name', 'Total Power vs Altitude: Cuboid', 'Color', 'w');
hold on;
for t = 1:5
    % g = 1 pulls the power data specifically for the Cuboid chassis
    plot(altArray, squeeze(totalPowerFinal(1, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Total Spacecraft Power Requirement vs. Altitude (Cuboid Chassis)');
xlabel('Altitude (km)');
ylabel('Total Power Required (W)');
legend(thrusterNames, 'Location', 'northeast');
% Cap Y-axis to keep the graph readable (Adjust this limit based on your data)
ylim([0, 500]);

% --- Graph 7: Total Power Requirement vs Altitude (Cylinder) ---
figure('Name', 'Total Power vs Altitude: Cylinder', 'Color', 'w');
hold on;
for t = 1:5
    % g = 2 pulls the power data specifically for the Cylindrical chassis
    plot(altArray, squeeze(totalPowerFinal(2, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Total Spacecraft Power Requirement vs. Altitude (Cylindrical Chassis)');
xlabel('Altitude (km)');
ylabel('Total Power Required (W)');
legend(thrusterNames, 'Location', 'northeast');

% Cap Y-axis to keep the graph readable (Adjust this limit based on your data)
ylim([0, 500]);

%ArefFinal(1, 3, 2)

% --- Graph 8: Reference Area vs Altitude (Cuboid) ---
figure('Name', 'Reference Area vs Altitude: Cuboid', 'Color', 'w');
hold on;
for t = 1:5
    % g = 1 pulls the Aref data specifically for the Cuboid chassis
    plot(altArray, squeeze(ArefFinal(1, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Reference Area (A_{ref}) vs. Altitude (Cuboid Chassis)');
xlabel('Altitude (km)');
ylabel('Reference Area (m^2)');
legend(thrusterNames, 'Location', 'northeast');
% Optional: ylim([0, 5]); % Uncomment and adjust if the PPT spikes ruin the scale

% --- Graph 9: Reference Area vs Altitude (Cylinder) ---
figure('Name', 'Reference Area vs Altitude: Cylinder', 'Color', 'w');
hold on;
for t = 1:5
    % g = 2 pulls the Aref data specifically for the Cylindrical chassis
    plot(altArray, squeeze(ArefFinal(2, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Reference Area (A_{ref}) vs. Altitude (Cylindrical Chassis)');
xlabel('Altitude (km)');
ylabel('Reference Area (m^2)');
legend(thrusterNames, 'Location', 'northeast');
% Optional: ylim([0, 5]); % Uncomment and adjust if the PPT spikes ruin the scale

% =========================================================================
% --- ADVANCED REVIEW GRAPHICS: MASS BUDGET & PMF ---
% =========================================================================

% --- Graph 10: Propellant Mass Fraction (PMF) ---
% PMF is the ultimate metric for VLEO. It proves how much of your satellite 
% is just fuel vs actual usable payload. (PMF = Propellant Mass / Wet Mass)

pmfCuboid = squeeze(propMassArray(1, :, :)) ./ squeeze(wetMass(1, :, :));
pmfCylinder = squeeze(propMassArray(2, :, :)) ./ squeeze(wetMass(2, :, :));

figure('Name', 'Propellant Mass Fraction vs Altitude', 'Color', 'w');
hold on;
for t = 1:5
    plot(altArray, pmfCuboid(t, :), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end
% Add the Cylinder Ion Thruster as a dashed line for direct comparison
plot(altArray, pmfCylinder(3, :), '--', 'LineWidth', 2.5, 'Color', colors(3), 'DisplayName', 'Ion Thruster (Cylinder Penalty)');
hold off;

grid on;
title('Propellant Mass Fraction (PMF) vs. Altitude (Cuboid Baseline)');
xlabel('Altitude (km)');
ylabel('PMF (M_{prop} / M_{wet})');
legend([thrusterNames, "Ion Thruster (Cylinder Penalty)"], 'Location', 'northeast');
ylim([0, 0.5]); % If a satellite is >50% fuel, it's a gas station, not a sensor.


% --- Graph 11: The Ultimate Slide 4 Mass Budget Breakdown ---
% This extracts the exact mass chunks at your 330.5 km baseline for the 
% Ion Thruster to visually prove WHY the Cuboid wins.

targetAlt = 330.5;
[~, baselineIdx] = min(abs(altArray - targetAlt));

% 1. Reconstruct the exact masses for Cuboid + Ion (g=1, t=3) at 330.5 km
cuboid_OTA = otaMass(baselineIdx);
cuboid_Batt = reqBattCapacityWhFinal(1, 3, baselineIdx) / BATTERY_DENSITY;
cuboid_Solar = solarArrayAreaFinal(1, 3, baselineIdx) * SOLAR_MASS_PER_M2;
cuboid_Bus = ((cuboid_OTA + cuboid_Batt + cuboid_Solar) / 0.55) * 0.45; % 45% of dry mass
cuboid_DryMargin = ((cuboid_OTA + cuboid_Batt + cuboid_Solar + cuboid_Bus) * DRY_MASS_MARGIN) - (cuboid_OTA + cuboid_Batt + cuboid_Solar + cuboid_Bus);
cuboid_Prop = propMassArray(1, 3, baselineIdx);

% 2. Reconstruct the exact masses for Cylinder + Ion (g=2, t=3) at 330.5 km
cyl_OTA = otaMass(baselineIdx);
cyl_Batt = reqBattCapacityWhFinal(2, 3, baselineIdx) / BATTERY_DENSITY;
cyl_Solar = solarArrayAreaFinal(2, 3, baselineIdx) * SOLAR_MASS_PER_M2;
cyl_Bus = ((cyl_OTA + cyl_Batt + cyl_Solar) / 0.55) * 0.45; 
cyl_DryMargin = ((cyl_OTA + cyl_Batt + cyl_Solar + cyl_Bus) * DRY_MASS_MARGIN) - (cyl_OTA + cyl_Batt + cyl_Solar + cyl_Bus);
cyl_Prop = propMassArray(2, 3, baselineIdx);

% 3. Format data for a Stacked Bar Chart
categories = {'Cuboid (Deployed Arrays)', 'Cylinder (Body-Mounted)'};
massMatrix = [
    cuboid_OTA, cuboid_Solar, cuboid_Batt, cuboid_Bus, cuboid_DryMargin, cuboid_Prop;
    cyl_OTA, cyl_Solar, cyl_Batt, cyl_Bus, cyl_DryMargin, cyl_Prop
];

figure('Name', 'Baseline Mass Budget Breakdown', 'Color', 'w');
b = bar(massMatrix, 'stacked', 'FaceColor', 'flat');

% Assign professional aerospace color coding
b(1).CData = [0 0.4470 0.7410];       % OTA (Blue)
b(2).CData = [0.9290 0.6940 0.1250];  % Solar (Yellow)
b(3).CData = [0.4660 0.6740 0.1880];  % Battery (Green)
b(4).CData = [0.5 0.5 0.5];           % Structure/Bus (Gray)
b(5).CData = [0.3 0.3 0.3];           % Dry Mass Margin (Dark Gray)
b(6).CData = [0.8500 0.3250 0.0980];  % Propellant (Red/Orange)

grid on;
title(sprintf('Mass Budget Breakdown at %.1f km (Ion Thruster)', targetAlt));
ylabel('Mass (kg)');
legend('Optical Payload', 'Solar Arrays', 'Batteries', 'Bus Structure', '20% Dry Mass Margin', 'Propellant (w/ Margin)', 'Location', 'northwest');
set(gca, 'xticklabel', categories, 'FontSize', 11, 'FontWeight', 'bold');
% =========================================================================
% --- Graph 11: The Ultimate Slide 4 Mass Budget Breakdown ---
targetAlt = 330.5;
[~, baselineIdx] = min(abs(altArray - targetAlt));

% Helper function to extract masses cleanly
extractMass = @(g_idx, t_idx) ...
    [otaMass(baselineIdx), ...
     solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2, ...
     reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY, ...
     ((otaMass(baselineIdx) + (reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY) + (solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2)) / 0.55) * 0.45, ...
     ((((otaMass(baselineIdx) + (reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY) + (solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2)) / 0.55)) * DRY_MASS_MARGIN) - (((otaMass(baselineIdx) + (reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY) + (solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2)) / 0.55)), ...
     propMassArray(g_idx, t_idx, baselineIdx)];

% Extract all 4 scenarios using the Ion Thruster (t=3)
massMatrix = [
    extractMass(1, 3); % 1: Cuboid Deployed
    extractMass(2, 3); % 2: Cylinder Body-Mounted
    extractMass(3, 3); % 3: Cuboid Body-Mounted
    extractMass(4, 3)  % 4: Cylinder Deployed
];

categories = {'Cuboid (Deployed Wings)', 'Cylinder (Body-Mounted)', 'Cuboid (Body-Mounted)', 'Cylinder (Parachute Wings)'};

figure('Name', '4-Way Configuration Trade: Baseline Mass Budget', 'Color', 'w', 'Position', [100, 100, 900, 600]);
b = bar(massMatrix, 'stacked', 'FaceColor', 'flat');

b(1).CData = [0 0.4470 0.7410];       % OTA (Blue)
b(2).CData = [0.9290 0.6940 0.1250];  % Solar (Yellow)
b(3).CData = [0.4660 0.6740 0.1880];  % Battery (Green)
b(4).CData = [0.5 0.5 0.5];           % Structure/Bus (Gray)
b(5).CData = [0.3 0.3 0.3];           % Dry Mass Margin (Dark Gray)
b(6).CData = [0.8500 0.3250 0.0980];  % Propellant (Red/Orange)

grid on;
title(sprintf('Mass Budget Configuration Showdown at %.1f km (Ion Thruster)', targetAlt), 'FontSize', 14);
ylabel('Total Wet Mass (kg)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Optical Payload', 'Solar Arrays', 'Batteries', 'Bus Structure', '20% Dry Mass Margin', 'Propellant (w/ Margin)', 'Location', 'northwest');
set(gca, 'xticklabel', categories, 'FontSize', 10, 'FontWeight', 'bold');

% =========================================================================
% --- THE MISSING CONFIGURATIONS: SOLAR ARRAY PROFILES ---
% =========================================================================

% --- Graph 12: Solar Array Area vs Altitude (Cuboid Body-Mounted) ---
figure('Name', 'Solar Area: Cuboid Body-Mounted (Area Starvation)', 'Color', 'w');
hold on;
for t = 1:5
    % g = 3 pulls the data specifically for Cuboid Body-Mounted
    plot(altArray, squeeze(solarArrayAreaFinal(3, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end

% NEW DYNAMIC LIMIT: Cuboid Body-Mounted (g=3)
% Limit = 2 usable faces * (Width * Length)
cuboidBodyMaxLimit = 2 .* squeeze(finalWidthFaceted(3, 3, :)) .* squeeze(finalLengthFaceted(3, 3, :));

plot(altArray, cuboidBodyMaxLimit, 'k--', 'LineWidth', 2.5, 'DisplayName', 'Absolute Packaging Limit (2 Faces)');
hold off;
grid on;
title('Required Solar Array Area vs. Altitude (Cuboid Body-Mounted)');
xlabel('Altitude (km)');
ylabel('Total Solar Array Area (m^2)');
legend([thrusterNames, "Absolute Packaging Limit (2 Faces)"], 'Location', 'northeast');
% Cap Y-axis high enough so you can see how badly the inefficient thrusters fail
ylim([0, 15]); 

% =========================================================================

% =========================================================================
% --- THE FINAL 4-WAY SHOWDOWN: DRAG, POWER, AND MASS (ION THRUSTER) ---
% =========================================================================

% --- Graph 14: The Systems Cascade (Drag and Power at 330.5 km) ---
figure('Name', '4-Way Trade: Drag and Power Cascade', 'Color', 'w', 'Position', [150, 150, 1000, 450]);

% Extract Drag Force in milliNewtons (mN) for the 4 configs (Ion Thruster)
dragData = [dragForceFinalArray(1, 3, baselineIdx), dragForceFinalArray(2, 3, baselineIdx), ...
            dragForceFinalArray(3, 3, baselineIdx), dragForceFinalArray(4, 3, baselineIdx)] * 1000;

% Extract Total Power (W)
powerData = [totalPowerFinal(1, 3, baselineIdx), totalPowerFinal(2, 3, baselineIdx), ...
             totalPowerFinal(3, 3, baselineIdx), totalPowerFinal(4, 3, baselineIdx)];

% Subplot 1: Drag Force
subplot(1,2,1);
b1 = bar(dragData, 'FaceColor', '#D95319');
title(sprintf('Aerodynamic Drag Force at %.1f km', targetAlt), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Drag Force (milliNewtons)', 'FontWeight', 'bold');
set(gca, 'xticklabel', categories, 'FontSize', 9, 'FontWeight', 'bold');
xtickangle(15);
grid on;

% Subplot 2: Total Power Required
subplot(1,2,2);
b2 = bar(powerData, 'FaceColor', '#EDB120');
title(sprintf('Total Power Required at %.1f km', targetAlt), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Total Power (Watts)', 'FontWeight', 'bold');
set(gca, 'xticklabel', categories, 'FontSize', 9, 'FontWeight', 'bold');
xtickangle(15);
grid on;


% --- Graph 15: 4-Way Wet Mass vs Altitude Showdown (Ion Thruster) ---
figure('Name', '4-Way Trade: Wet Mass vs Altitude', 'Color', 'w');
hold on;

% distinct colors for the 4 configurations
configColors = ["#0072BD", "#D95319", "#EDB120", "#7E2F8E"]; 

for g = 1:4
    % Plotting only the Ion Thruster (t=3) for all 4 shapes
    plot(altArray, squeeze(wetMass(g, 3, :)), '-x', 'MarkerSize', 7, 'LineWidth', 2.5, 'Color', configColors(g));
end

hold off;
grid on;
title('Total Wet Mass vs. Altitude (Ion Thruster Isolator)', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Total Wet Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
legend(categories, 'Location', 'northeast', 'FontSize', 10);

% Cap Y-axis so the death spirals don't ruin the scale, keeping the baseline visible
ylim([0, 1000]); 

% =========================================================================
% --- Graph 13: Solar Array Area vs Altitude (Cylinder Deployed) ---
figure('Name', 'Solar Area: Cylinder Deployed', 'Color', 'w');
hold on;
for t = 1:5
    % g = 4 pulls the data specifically for Cylinder Deployed (The Parachute)
    plot(altArray, squeeze(solarArrayAreaFinal(4, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end

% NEW DYNAMIC STOWAGE LIMIT
% 6 Panels Total (3-panel Z-fold on 2 deployed wings)
% Tangential stowage footprint on a cylinder is projected width * length
cylStowageMaxLimit = 6 .* squeeze(finalWidthCylinder(4, 3, :)) .* squeeze(finalLengthCylinder(4, 3, :));

plot(altArray, cylStowageMaxLimit, 'k--', 'LineWidth', 2.5, 'DisplayName', 'Rigid Stowage Limit (6-Panel Z-Fold)');
hold off;
grid on;
title('Required Solar Array Area vs. Altitude (Cylinder with Deployed Wings)');
xlabel('Altitude (km)');
ylabel('Total Solar Array Area (m^2)');
legend([thrusterNames, "Rigid Stowage Limit (6-Panel Z-Fold)"], 'Location', 'northeast');
ylim([0, 15]);
% =========================================================================
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

% =========================================================================
% --- MISSING MASS PROFILE: CYLINDER DEPLOYED ---
% =========================================================================

% --- Graph 16: Wet Mass vs Altitude (Cylinder Deployed) ---
figure('Name', 'Wet Mass vs Altitude: Cylinder Deployed', 'Color', 'w');
hold on;
for t = 1:5
    % g = 4 pulls the Wet Mass data specifically for the Cylinder with Parachute Wings
    plot(altArray, squeeze(wetMass(4, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Total Wet Mass vs. Altitude (Cylinder with Deployed Wings)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Total Wet Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
legend(thrusterNames, 'Location', 'northeast', 'FontSize', 10);

% Cap Y-axis so the PPT and Resistojet death spirals do not wash out the scale
ylim([0, 1000]);

% =========================================================================
% --- Graph 17: NADIR DECK GEOMETRIC PACKAGING TRADE ---
% =========================================================================

% Ensure we are using the baseline telescope diameter (approx 0.82m)
baselineDiameter = apertureDiameter(baselineIdx);
circleArea = pi * (baselineDiameter / 2)^2;

% Define the polygons to test [Square, Pentagon, Hexagon, Octagon]
n_sides = [4, 5, 6, 8];
labels = {'Cuboid (4 Sides)', 'Pentagon (5 Sides)', 'Hexagon (6 Sides)', 'Octagon (8 Sides)'};
freeSpacePerCorner = zeros(1, 4);

% Calculate the geometric area and corner space for each bounding polygon
for i = 1:length(n_sides)
    n = n_sides(i);
    % Formula for the area of a regular polygon bounding a circle of diameter D
    polyArea = (n/4) * baselineDiameter^2 * tan(pi/n);
    totalFree = polyArea - circleArea;
    freeSpacePerCorner(i) = totalFree / n;
end

figure('Name', 'Nadir Deck Packaging Trade', 'Color', 'w', 'Position', [200, 200, 800, 500]);
b = bar(freeSpacePerCorner, 'FaceColor', 'flat');

% Assign presentation-grade colors to tell the story automatically
b.CData(1,:) = [0.4660 0.6740 0.1880]; % Cuboid: Green (Passes easily)
b.CData(2,:) = [0.9290 0.6940 0.1250]; % Pentagon: Yellow (Passes math, fails flight dynamics)
b.CData(3,:) = [0.8500 0.3250 0.0980]; % Hexagon: Red (Fails hardware limit)
b.CData(4,:) = [0.8500 0.3250 0.0980]; % Octagon: Red (Fails hardware limit entirely)

hold on;
% Draw the strict Hardware Limitation line based on real COTS data
yline(0.0100, 'k--', 'LineWidth', 3, 'DisplayName', 'COTS Hardware Limit (0.01 m^2)');
hold off;

grid on;
title(sprintf('Nadir Deck Corner Space vs. Bus Geometry (D = %.2f m)', baselineDiameter), 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Usable Free Space Per Corner (m^2)', 'FontSize', 11, 'FontWeight', 'bold');
set(gca, 'xticklabel', labels, 'FontSize', 10, 'FontWeight', 'bold');
legend('Available Corner Real Estate', 'COTS Antenna Footprint', 'Location', 'northeast');

% Add a text callout for the Hexagon failure
text(3, freeSpacePerCorner(3) + 0.001, 'Fails by 10 cm^2', 'HorizontalAlignment', 'center', 'Color', 'r', 'FontWeight', 'bold');
% =========================================================================


% =========================================================================
% --- Graph 18: WET MASS VS ALTITUDE (HEXAGON DEPLOYED) ---
% =========================================================================

figure('Name', 'Wet Mass vs Altitude: Hexagon Deployed', 'Color', 'w');
hold on;
for t = 1:5
    % g = 5 pulls the Wet Mass data specifically for the Hexagonal Bus with Wings
    plot(altArray, squeeze(wetMass(5, t, :)), "-x", 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Color', colors(t));
end
hold off;
grid on;
title('Total Wet Mass vs. Altitude (Hexagonal Bus with Deployed Wings)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Total Wet Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
legend(thrusterNames, 'Location', 'northeast', 'FontSize', 10);

% Cap Y-axis so the PPT and Resistojet failures do not wash out the scale
ylim([0, 1000]); 
% =========================================================================

% =========================================================================
% --- Graph 11: The Ultimate Slide 4 Mass Budget Breakdown (5-Way) ---
% =========================================================================
targetAlt = 330.5;
[~, baselineIdx] = min(abs(altArray - targetAlt));

% Helper function to extract masses cleanly
extractMass = @(g_idx, t_idx) ...
    [otaMass(baselineIdx), ...
     solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2, ...
     reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY, ...
     ((otaMass(baselineIdx) + (reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY) + (solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2)) / 0.55) * 0.45, ...
     ((((otaMass(baselineIdx) + (reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY) + (solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2)) / 0.55)) * DRY_MASS_MARGIN) - (((otaMass(baselineIdx) + (reqBattCapacityWhFinal(g_idx, t_idx, baselineIdx) / BATTERY_DENSITY) + (solarArrayAreaFinal(g_idx, t_idx, baselineIdx) * SOLAR_MASS_PER_M2)) / 0.55)), ...
     propMassArray(g_idx, t_idx, baselineIdx)];

% Extract all 5 scenarios using the Ion Thruster (t=3)
massMatrix = [
    extractMass(1, 3); % 1: Cuboid Deployed
    extractMass(2, 3); % 2: Cylinder Body-Mounted
    extractMass(3, 3); % 3: Cuboid Body-Mounted
    extractMass(4, 3); % 4: Cylinder Deployed
    extractMass(5, 3)  % 5: Hexagon Deployed
];

categories5 = {'Cuboid (Deployed)', 'Cylinder (Body-Mt)', 'Cuboid (Body-Mt)', 'Cylinder (Deployed)', 'Hexagon (Deployed)'};

figure('Name', '5-Way Configuration Trade: Baseline Mass Budget', 'Color', 'w', 'Position', [100, 100, 1000, 600]);
b = bar(massMatrix, 'stacked', 'FaceColor', 'flat');

b(1).CData = [0 0.4470 0.7410];       % OTA (Blue)
b(2).CData = [0.9290 0.6940 0.1250];  % Solar (Yellow)
b(3).CData = [0.4660 0.6740 0.1880];  % Battery (Green)
b(4).CData = [0.5 0.5 0.5];           % Structure/Bus (Gray)
b(5).CData = [0.3 0.3 0.3];           % Dry Mass Margin (Dark Gray)
b(6).CData = [0.8500 0.3250 0.0980];  % Propellant (Red/Orange)

grid on;
title(sprintf('Mass Budget Configuration Showdown at %.1f km (Ion Thruster)', targetAlt), 'FontSize', 14);
ylabel('Total Wet Mass (kg)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Optical Payload', 'Solar Arrays', 'Batteries', 'Bus Structure', '20% Dry Mass Margin', 'Propellant (w/ Margin)', 'Location', 'northwest');
set(gca, 'xticklabel', categories5, 'FontSize', 9, 'FontWeight', 'bold');

% =========================================================================
% --- THE FINAL 5-WAY SHOWDOWN: DRAG, POWER, AND MASS (ION THRUSTER) ---
% =========================================================================

% --- Graph 14: The Systems Cascade (Drag and Power at 330.5 km) ---
figure('Name', '5-Way Trade: Drag and Power Cascade', 'Color', 'w', 'Position', [150, 150, 1100, 450]);

% Extract Drag Force in milliNewtons (mN) for the 5 configs (Ion Thruster)
dragData = [dragForceFinalArray(1, 3, baselineIdx), dragForceFinalArray(2, 3, baselineIdx), ...
            dragForceFinalArray(3, 3, baselineIdx), dragForceFinalArray(4, 3, baselineIdx), ...
            dragForceFinalArray(5, 3, baselineIdx)] * 1000;

% Extract Total Power (W)
powerData = [totalPowerFinal(1, 3, baselineIdx), totalPowerFinal(2, 3, baselineIdx), ...
             totalPowerFinal(3, 3, baselineIdx), totalPowerFinal(4, 3, baselineIdx), ...
             totalPowerFinal(5, 3, baselineIdx)];

% Subplot 1: Drag Force
subplot(1,2,1);
b1 = bar(dragData, 'FaceColor', '#D95319');
title(sprintf('Aerodynamic Drag Force at %.1f km', targetAlt), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Drag Force (milliNewtons)', 'FontWeight', 'bold');
set(gca, 'xticklabel', categories5, 'FontSize', 8, 'FontWeight', 'bold');
xtickangle(15); % Angled text so the 5 labels don't crash into each other
grid on;

% Subplot 2: Total Power Required
subplot(1,2,2);
b2 = bar(powerData, 'FaceColor', '#EDB120');
title(sprintf('Total Power Required at %.1f km', targetAlt), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Total Power (Watts)', 'FontWeight', 'bold');
set(gca, 'xticklabel', categories5, 'FontSize', 8, 'FontWeight', 'bold');
xtickangle(15);
grid on;


% --- Graph 15: 5-Way Wet Mass vs Altitude Showdown (Ion Thruster) ---
figure('Name', '5-Way Trade: Wet Mass vs Altitude', 'Color', 'w');
hold on;

% Distinct colors for the 5 configurations (Added Green for Hexagon)
configColors = ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30"]; 

for g = 1:5
    % Plotting only the Ion Thruster (t=3) for all 5 shapes
    plot(altArray, squeeze(wetMass(g, 3, :)), '-x', 'MarkerSize', 7, 'LineWidth', 2.5, 'Color', configColors(g));
end

hold off;
grid on;
title('Total Wet Mass vs. Altitude (Ion Thruster Isolator)', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Total Wet Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
legend(categories5, 'Location', 'northeast', 'FontSize', 9);

% Cap Y-axis so the baseline stays highly visible
ylim([0, 1000]); 
% =========================================================================

% =========================================================================
% --- PHASE B MECHANICAL PACKAGING TRADE STUDY (REFINED) ---
% =========================================================================

% 1. Define the Math Data (Updated Labels to show clearance)
shapes = categorical({'Cyl (10cm clear)', 'Cyl (20cm clear)', 'Hex (10cm clear)', 'Cuboid (10cm clear)'});
shapes = reordercats(shapes, {'Cyl (10cm clear)', 'Cyl (20cm clear)', 'Hex (10cm clear)', 'Cuboid (10cm clear)'}); 

% Radial Depths (cm)
depths = [5.0, 10.0, 12.1, 24.0]; 

% Usable Area per Corner/Mounting Pocket (m^2)
areas = [0.0, 0.010, 0.034, 0.079]; 

% 2. Setup the Presentation Figure (Slightly wider to accommodate new labels)
figClearance = figure('Name', 'Antenna Packaging Trade Study', 'Color', 'w', 'Position', [150, 150, 1050, 550]);

% -------------------------------------------------------------------------
% SUBPLOT 1: Maximum Radial Depth
% -------------------------------------------------------------------------
subplot(1, 2, 1);
b1 = bar(shapes, depths);
b1.FaceColor = 'flat';
b1.CData(1,:) = [0.85, 0.32, 0.09]; % Red (Fails)
b1.CData(2,:) = [0.30, 0.74, 0.93]; % Light Blue (Passes, but bloated A_ref)
b1.CData(3,:) = [0.46, 0.67, 0.18]; % Green (Hexagon Wins)
b1.CData(4,:) = [0.92, 0.69, 0.12]; % Yellow (Cuboid Excess)

hold on; grid on;
% Moved label to the RIGHT and BOTTOM so it does not intersect the bars
yline(10, 'r--', 'LineWidth', 2, 'Label', 'Required Depth (10 cm)', ...
    'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom');
ylabel('Maximum Radial Depth (cm)', 'FontWeight', 'bold');
title('Radial Clearance by Shape', 'FontSize', 14);
ylim([0 30]);

% Increased vertical offset (+1.2) for cleaner spacing
for i = 1:4
    text(i, depths(i) + 1.2, sprintf('%.1f cm', depths(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
end

% -------------------------------------------------------------------------
% SUBPLOT 2: Usable Area Per Mounting Pocket
% -------------------------------------------------------------------------
subplot(1, 2, 2);
b2 = bar(shapes, areas);
b2.FaceColor = 'flat';
b2.CData(1,:) = [0.85, 0.32, 0.09]; % Red
b2.CData(2,:) = [0.30, 0.74, 0.93]; % Light Blue
b2.CData(3,:) = [0.46, 0.67, 0.18]; % Green
b2.CData(4,:) = [0.92, 0.69, 0.12]; % Yellow

hold on; grid on;
% Moved label to the RIGHT and BOTTOM to avoid the 0.010 m^2 text overlap
yline(0.01, 'r--', 'LineWidth', 2, 'Label', 'Required Area (0.01 m^2)', ...
    'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom');
ylabel('Usable Area per Mounting Zone (m^2)', 'FontWeight', 'bold');
title('Usable Mounting Area', 'FontSize', 14);
ylim([0 0.1]);

% Increased vertical offset (+0.004) for cleaner spacing
for i = 1:4
    if areas(i) == 0
        text(i, areas(i) + 0.004, 'Fails', ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'r');
    else
        text(i, areas(i) + 0.004, sprintf('%.3f m^2', areas(i)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
    end
end
% =========================================================================


reqBattCapacityWhFinal(2, 3, 2)


% =========================================================================
% --- ISOLATED TRADE: CYLINDER BODY-MOUNTED VS DEPLOYED WINGS ---
% =========================================================================
% This figure isolates the Ion Thruster (t=3) to show the massive aerodynamic 
% penalty of deploying wings on an otherwise aerodynamic cylinder.

figure('Name', 'Trade: Cylinder Array Configuration', 'Color', 'w', 'Position', [150, 150, 1000, 450]);

% Subplot 1: Required Solar Array Area (The Power Penalty)
subplot(1,2,1);
hold on;
% g = 2: Body-Mounted
plot(altArray, squeeze(solarArrayAreaFinal(2, 3, :)), '-x', 'MarkerSize', 7, 'LineWidth', 2.5, 'Color', '#0072BD', 'DisplayName', 'Body-Mounted (Wraparound)');
% g = 4: Deployed Wings
plot(altArray, squeeze(solarArrayAreaFinal(4, 3, :)), '-o', 'MarkerSize', 7, 'LineWidth', 2.5, 'Color', '#D95319', 'DisplayName', 'Deployed Wings (High Drag)');
hold off;
grid on;
title('Required Solar Area vs. Altitude (Ion Thruster)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Solar Array Area (m^2)', 'FontSize', 11, 'FontWeight', 'bold');
legend('Location', 'northeast');
ylim([0, 15]); % Kept consistent with your other limits

% Subplot 2: Total Wet Mass (The Final Consequence)
subplot(1,2,2);
hold on;
% g = 2: Body-Mounted
plot(altArray, squeeze(wetMass(2, 3, :)), '-x', 'MarkerSize', 7, 'LineWidth', 2.5, 'Color', '#0072BD', 'DisplayName', 'Body-Mounted (Low A_{ref})');
% g = 4: Deployed Wings
plot(altArray, squeeze(wetMass(4, 3, :)), '-o', 'MarkerSize', 7, 'LineWidth', 2.5, 'Color', '#D95319', 'DisplayName', 'Deployed Wings (Drag Death Spiral)');
hold off;
grid on;
title('Total Wet Mass vs. Altitude (Ion Thruster)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Altitude (km)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Total Wet Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
legend('Location', 'northeast');
ylim([0, 1000]); % Kept consistent with your other limits