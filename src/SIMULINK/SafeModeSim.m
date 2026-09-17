% --- Safe Mode Orbital Decay Simulation (72-Hour Storm) ---
% Demonstrates survivability during extreme ap=300 space weather

% 1. Spacecraft & Environment Parameters (UPDATE THESE)
m = 99;                  % UPDATE: Your Cuboid's total wetMass in kg
Aref_feathered = 0.2896;   % UPDATE: Your feathered Aref (use the Cylinder's baseline area)
Cd = 2.38;                % Drag coefficient
rho_storm = 5e-11;       % Extreme storm density at 330km (kg/m^3)

% 2. Orbital Constants
mu = 3.986e14;           % Earth's gravitational constant (m^3/s^2)
Re = 6371e3;             % Earth's radius (m)
alt_initial = 330.5e3;   % Starting altitude (m)
a = Re + alt_initial;    % Initial semi-major axis

% 3. Simulation Setup
time_hours = 72;                 % Duration of extreme storm
dt = 60;                         % 1-minute time steps (seconds)
steps = (time_hours * 3600) / dt; 

altitude_log = zeros(1, steps);
time_log = linspace(0, time_hours, steps);

% Initial Orbital Energy
E_total = -mu / (2 * a);

% 4. Integration Loop
for i = 1:steps
    % Current velocity
    v = sqrt(mu / a); 
    
    % Drag Force (N)
    F_drag = 0.5 * rho_storm * v^2 * Cd * Aref_feathered; 
    
    % Energy lost to drag in this time step (Work = Force * Distance)
    % Distance = velocity * time step
    dE = F_drag * (v * dt); 
    
    % Specific energy update (Energy per kg)
    E_total = E_total - (dE / m); 
    
    % Calculate new semi-major axis and altitude
    a = -mu / (2 * E_total);
    alt_current = a - Re;
    
    % Log the altitude (converted to km)
    altitude_log(i) = alt_current / 1000;
end

% 5. Plotting the Proof
figure('Name', 'Safe Mode Orbital Decay', 'Color', 'w');
plot(time_log, altitude_log, 'LineWidth', 2, 'Color', '#7E2F8E');
grid on; box on;
title('Cuboid Safe Mode: 72-Hour Extreme Storm Drift');
xlabel('Time in Storm (Hours)');
ylabel('Altitude (km)');

%%
% --- End of Life (EoL) Natural Orbital Decay Simulation ---
% Demonstrates compliance with the ESA/FCC 5-Year Deorbit Rule

% 1. Spacecraft Parameters (UPDATE THESE)
m = 99.8;                % EoL Mass (Use Dry Mass if propellant is fully depleted)
Aref_tumbling = 0.2896;     % UPDATE: Use your average tumbling or deployed area (m^2)
Cd = 2.36;               % Drag coefficient

% 2. Orbital Constants
mu = 3.986e14;           % Earth's gravitational constant (m^3/s^2)
Re = 6378e3;             % Earth's radius (m)
alt_current = 330.5e3;   % Starting altitude (m)
alt_burnup = 150e3;      % Destructive re-entry altitude (m)
a = Re + alt_current;    % Initial semi-major axis

% 3. Simulation Setup
dt = 3600;               % 1-hour time steps (faster processing for multi-month sim)
time_elapsed = 0;        % Seconds
max_seconds = 5 * 365.25 * 24 * 3600; % 5 Years maximum

altitude_log = [];
time_log = [];
E_total = -mu / (2 * a);

% 4. Integration Loop (Run until burn-up OR 5 years)
while (alt_current > alt_burnup) && (time_elapsed < max_seconds)
    % Current velocity
    v = sqrt(mu / a); 
    
    % Exponential Atmospheric Density Model (Approximate VLEO Scale Height)
    % Density increases exponentially as altitude drops
    rho = 2e-11 * exp(-(alt_current - 330000) / 45000); 
    
    % Drag Force (N)
    F_drag = 0.5 * rho * v^2 * Cd * Aref_tumbling; 
    
    % Energy lost to drag in this time step
    dE = F_drag * (v * dt); 
    
    % Specific energy update
    E_total = E_total - (dE / m); 
    
    % Calculate new semi-major axis and altitude
    a = -mu / (2 * E_total);
    alt_current = a - Re;
    
    % Step time forward
    time_elapsed = time_elapsed + dt;
    
    % Log the data once per day (86400 seconds) to keep the graph clean
    if mod(time_elapsed, 86400) == 0
        altitude_log(end+1) = alt_current / 1000;
        time_log(end+1) = time_elapsed / 86400; % Convert to days
    end

    % Force-log the final burn-up datapoint after the loop breaks
    altitude_log(end+1) = alt_current / 1000;
    time_log(end+1) = time_elapsed / 86400;
end

% 5. Plotting the Proof
figure('Name', 'EoL Orbital Decay', 'Color', 'w');
plot(time_log, altitude_log, 'LineWidth', 2.5, 'Color', '#D95319');
grid on; box on;
title('Zero-Propellant End of Life Demise');
xlabel('Time After Engine Deactivation (Days)');
ylabel('Altitude (km)');
yline(150, '--r', 'Atmospheric Burn-Up Threshold (150 km)', ...
    'LabelHorizontalAlignment', 'right', 'LineWidth', 1.5);

% Output final tally to command window
disp(['Natural deorbit achieved in: ', num2str(time_log(end)), ' days.']);