% =========================================================================
% --- AERODYNAMIC STABILITY: FREE BODY DIAGRAM ---
% Proves why an aerodynamic wedge nosecone causes catastrophic tumbling
% =========================================================================

figStability = figure('Name', 'Aerodynamic Stability Analysis', 'Color', 'w', 'Position', [200, 200, 1000, 450]);

% -------------------------------------------------------------------------
% SUBPLOT 1: The Stable Hexagon (Baseline)
% -------------------------------------------------------------------------
subplot(1, 2, 1); hold on; axis equal; axis off;
title('Baseline Hexagon: Aerodynamically Stable', 'FontSize', 14, 'FontWeight', 'bold');

% Draw side profile of Hexagon (Rectangle in 2D)
patch([-1 1 1 -1], [-0.5 -0.5 0.5 0.5], [0.46 0.67 0.18], 'FaceAlpha', 0.8, 'EdgeColor', 'k', 'LineWidth', 2);

% Plot CoM (Heavy telescope in the center)
plot(0, 0, 'ko', 'MarkerSize', 14, 'LineWidth', 2, 'MarkerFaceColor', 'w');
plot(0, 0, 'k+', 'MarkerSize', 14, 'LineWidth', 2);
text(0, 0.7, 'CoM', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);

% Plot CoP (Pressure distributed evenly on flat ram face)
plot(-1, 0, 'r*', 'MarkerSize', 12, 'LineWidth', 2);
text(-1.1, 0.7, 'CoP', 'Color', 'r', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);

% Wind Vectors
quiver(-2.5, 0.3, 1, 0, 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.5);
quiver(-2.5, -0.3, 1, 0, 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.5);
text(-2.5, 0.6, 'ATOX Wind', 'Color', 'b', 'FontWeight', 'bold', 'FontSize', 11);

% Note on stability
text(0, -1.2, 'CoP is at or behind CoM.', 'HorizontalAlignment', 'center', 'FontSize', 11);
text(0, -1.5, 'Zero overturning torque. ADCS is safe.', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', [0.1 0.5 0.1]);
xlim([-3 2]); ylim([-2 2]);

% -------------------------------------------------------------------------
% SUBPLOT 2: The Unstable Wedge Concept
% -------------------------------------------------------------------------
subplot(1, 2, 2); hold on; axis equal; axis off;
title('Wedge Nosecone: Unstable (Tumble Risk)', 'FontSize', 14, 'FontWeight', 'bold');

% Draw side profile of Hexagon body
patch([-1 1 1 -1], [-0.5 -0.5 0.5 0.5], [0.8 0.8 0.8], 'FaceAlpha', 0.8, 'EdgeColor', 'k', 'LineWidth', 2);
% Draw the aerodynamic wedge nosecone
patch([-2.5 -1 -1], [0 0.5 -0.5], [0.85 0.32 0.09], 'FaceAlpha', 0.8, 'EdgeColor', 'k', 'LineWidth', 2);

% Plot CoM (Heavy telescope is STILL in the main body)
plot(0, 0, 'ko', 'MarkerSize', 14, 'LineWidth', 2, 'MarkerFaceColor', 'w');
plot(0, 0, 'k+', 'MarkerSize', 14, 'LineWidth', 2);
text(0, 0.7, 'CoM', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);

% Plot CoP (Shifted massively forward onto the wedge)
plot(-2.0, 0, 'r*', 'MarkerSize', 12, 'LineWidth', 2);
text(-2.0, 0.7, 'CoP', 'Color', 'r', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);

% Wind Vectors
quiver(-3.5, 0.3, 0.8, -0.2, 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.5);
quiver(-3.5, -0.3, 0.8, 0.2, 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.5);

% Draw the massive overturning Torque arrow
theta = linspace(pi/2, 3*pi/2, 50);
plot(0.8*cos(theta)-1, 0.8*sin(theta), 'r', 'LineWidth', 3);
quiver(-1, 0.8, 0.1, 0, 0, 'r', 'LineWidth', 3, 'MaxHeadSize', 2); % Arrowhead
text(-1.5, 1.2, 'Overturning Torque', 'Color', 'r', 'FontWeight', 'bold', 'FontSize', 12);

% Equation: T = F * d
text(-1, -1.2, 'Moment Arm (d) = 2.0 m', 'Color', 'r', 'HorizontalAlignment', 'center', 'FontSize', 11);
text(-1, -1.5, 'Satellite flips. ADCS failure.', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'r');
xlim([-4 2]); ylim([-2 2]);
% =========================================================================