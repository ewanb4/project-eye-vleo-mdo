clear;
clc;
close all

% 1. Launch the 3D Simulation Viewer
scenario = satelliteScenario;

% 2. Add your winning Cuboid Satellite
% Inputs: semi-major axis (meters), eccentricity, inclination, RAAN, Arg of Perigee, True Anomaly
cuboidSat = satellite(scenario, 330578 + 6371000, 0, 97.6, 0, 0, 0, "Name", "VLEO Cuboid");

% 3. Attach your Camera (Conical Sensor) with the 45-degree roll capability
% A 45-degree roll left/right means your total cone angle is 90 degrees
cam = conicalSensor(cuboidSat, "MaxViewAngle", 90, "Name", "1.0m Telescope FoR");

% 4. Run the visualizer 
play(scenario);