%% Inputs
% Battery
Bat_DoD = 0.3;
Bat_SED = 125; % Specific Energy Density [W-hr/kg]

% Solar Array
SA_Eff = 0.2;
SA_Deg = 0.03; % Solar Array Performance degredation [%/year]
SA_Pack = 0.85;
SA_Theta = 25; % deg
q_Sun = 1400; % W/m2

Lifetime = 5; % Years
Sat_P = 1500; % Baseline Power Requirement [W]

%% Eclipse Time
EclipseFrac = mean(out.EclipseFrac.Data);
T_P = (3600*24)/14.30818589; % Orbit Period [s]
T_E = EclipseFrac * T_P; % Eclipse Time [s]
T_S = T_P - T_E; % Sunlit Time [s]

%% Eclipse Power

% Power in Eclipse (no charging or propulsion) [W]
E_E = (Sat_P * T_E); % Eclipse Energy [W-s]

% Batteries
Bat_Cap = (E_E/3600)/Bat_DoD; % Battery Capacity [W-hr]
Batt_Mass = Bat_Cap/Bat_SED; % [kg]

%% Sunlit Power
P_charge = E_E/T_S; % Charging Power [W]
P_S = (Sat_P + P_charge); % Sunlit Power (inc. charging) [W]

% Required Solar Array Power
%E_S = P_S*T_S; % Energy Required in Sunlight [W-s]
%P_array = (E_E/input.eps.XE + E_S/input.eps.XS)/data.mission.T_S;

rho_BoL = SA_Eff * SA_Pack * q_Sun; % Power density BoL [W/m2]
rho_EoL = rho_BoL*(1-SA_Deg)^Lifetime; % Power density EoL [W/m2]

SA_Area = P_S / (rho_EoL * cosd(SA_Theta)); % Solar Array Area [m^2]