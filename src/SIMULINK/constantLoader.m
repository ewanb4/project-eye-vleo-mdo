% SIMULINK CONSTANT LOADER
clear;

% Cuboid (Deployed) - 330.5km alt + ion thruster
cd = 2.41;
velocity = 7.7082 * 1000;
Aref = 2.7952;
Isp = 3050;
eta = 0.6;
batCap = 370;
SA_Area = 1.1017;
areaFeathered = Aref - SA_Area;

% Cylinder (Face) - 330.5km + ion Thruster
%%
cd = 2.2;
velocity = 7.7082 * 1000;
Aref = 1.34573;
Isp = 3050;
eta = 0.6;
batCap = 330;
SA_Area = 3.07 / pi;

%% Cylinder (Deployed)

cd = 2.28;
velocity = 7.7082 * 1000;
Aref = 2.3669;
Isp = 3050;
eta = 0.6;
batCap = 350;
SA_Area = 1.1264;
areaFeathered = Aref - SA_Area;

%% Hexagon (Deployed)

cd = 2.36;
velocity = 7.7082 * 1000;
Aref = 2.7794;
Isp = 3050;
eta = 0.6;
batCap = 370;
SA_Area = 1.0858;
areaFeathered = Aref - SA_Area;

%% TDI
% Hexagon


cd = 2.36;
velocity = 7.7082 * 1000;
Aref = 1.1666;
Isp = 3050;
eta = 0.6;
batCap = 300;
SA_Area = 0.8770;
areaFeathered = Aref - SA_Area;
