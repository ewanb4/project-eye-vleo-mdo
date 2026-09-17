% =========================================================================
% --- SLIDE 2: EMPIRICAL VLEO DENSITY WALL (NRLMSISE-00) ---
% =========================================================================
% NOTE: This script requires the MATLAB Aerospace Toolbox.

% 1. Define Extended Altitude Range (200 km to 1500 km)
alt_km = linspace(200, 1500, 1000);
alt_m = alt_km .* 1000; % The NRLMSISE-00 function requires altitude in meters

% 2. Define Space Environment Parameters (Mean Solar Activity Baseline)
year = 2026;
dayOfYear = 172;        % Summer Solstice
UTseconds = 43200;      % Noon (12:00:00 UT)
lat = 0;                % Equator
lon = 0;
f107Average = 150;      % Mean 81-day solar activity (F10.7 flux)
f107Daily = 150;        % Daily solar activity
magneticIndex = 4;      % Quiet geomagnetic activity (Ap index)

% 3. Preallocate density array for speed
rho_total = zeros(length(alt_km), 1);

% 4. Query the NRLMSISE-00 Model
% The function returns a 9-element density array for each altitude.
% The 6th element is the Total Mass Density (kg/m^3).
for i = 1:length(alt_km)
    [~, rho] = atmosnrlmsise00(alt_m(i), lat, lon, year, dayOfYear, ...
                               UTseconds, f107Average, f107Daily, magneticIndex);
    rho_total(i) = rho(6);
end

% 5. Initialize Figure
figure('Name', 'Slide 2: Empirical Density Wall', 'Color', 'w', 'Position', [150, 150, 900, 500]);
semilogy(alt_km, rho_total, 'k-', 'LineWidth', 3);
hold on; grid on;

% 6. Fill the "VLEO Regime" Danger Zone (Under 450 km)
vleo_idx = alt_km <= 450;
area(alt_km(vleo_idx), rho_total(vleo_idx), 'FaceColor', '#D95319', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 7. Add an authoritative label for the VLEO region
text(325, 1e-16, 'VLEO Regime (< 450 km)', 'FontSize', 16, 'FontWeight', 'bold', ...
     'Color', '#D95319', 'HorizontalAlignment', 'center', ...
     'BackgroundColor', [1 1 1 0.8], 'EdgeColor', '#D95319', 'Margin', 3);

% 8. Set Tick Mark Sizes FIRST (Order of Operations)
set(gca, 'FontSize', 14, 'FontWeight', 'bold');

% 9. Final Professional Formatting
title('Atmospheric Density vs. Altitude (NRLMSISE-00 Model)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Orbital Altitude (km)', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Total Mass Density (kg/m^3) - Log Scale', 'FontSize', 16, 'FontWeight', 'bold');

% Frame the graph perfectly
xlim([200, 1500]);
ylim([1e-18, 1e-9]); % Standard bounds to show the drop-off
set(gca, 'Layer', 'top'); 
hold off;