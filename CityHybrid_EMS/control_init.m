%% CityHybrid ME325 - Master Initialization Script
% Series Hybrid L7e Three-Wheeler
% Colombo Urban Drive Cycle target
clear; clc;
disp('Initializing CityHybrid Powertrain Model...');

%% 1. Drive Cycle Data Extraction
% Read the clean WebPlotDigitizer CSV file
raw_data = readmatrix('colombo_clean.csv');

% Crop out any potential "Negative Time" ghost data
valid_data = raw_data(raw_data(:,1) >= 0, :);

% Extract columns and eliminate duplicate time stamps
[time_sec, unique_indices] = unique(valid_data(:, 1));
speed_kmh = valid_data(unique_indices, 2);

% Force the very first time step to be exactly 0 (for Simulink)
time_sec(1) = 0;

% CONTINUOUS LOOPING LOGIC 
num_loops = 4; % Change this number to drive the cycle more or fewer times

% Force the data into vertical column vectors to prevent dimension mismatch errors
time_sec = time_sec(:);
speed_kmh = speed_kmh(:);

time_looped = time_sec;
speed_looped = speed_kmh;

for i = 2:num_loops
    % Append the time vector, offsetting it by the exact duration of the previous loop.
    % The %#ok<AGROW> flags tell MATLAB to turn off the orange warning lines.
    time_looped = [time_looped; time_sec(2:end) + time_looped(end)];
    speed_looped = [speed_looped; speed_kmh(2:end)];
end

% Create the finalized Simulink-friendly Timeseries object
colombo_drive_cycle = timeseries(speed_looped, time_looped);

disp([' - Drive cycle loaded and looped ', num2str(num_loops), ' times!']);
disp([' - New Total Simulation Time: ', num2str(time_looped(end)), ' seconds.']);

%% 2. Vehicle Physical Parameters (L7e Category Tuk-Tuk)
m    = 550;        % Total vehicle mass incl. payload [kg]
g    = 9.81;       % Gravitational acceleration [m/s^2]

% Aerodynamics
Cd   = 0.4;        % Drag coefficient (boxy Tuk-Tuk shape)
A    = 2.08;       % Frontal area [m^2]
rho  = 1.18;       % Air density at sea level in Colombo [kg/m^3]

% Rolling resistance & Wheel geometry
Crr  = 0.015;      % Rolling resistance coefficient
r_w  = 0.265;      % Wheel radius [m]

% Road grade
theta = 0;         % Flat road for baseline simulation [rad]

% Derived constant forces
F_rolling = Crr * m * g;          % Constant rolling resistance [N]
F_grade   = m * g * sin(theta);   % Slope force [N] (0 for flat)

disp(' - Vehicle physics parameters loaded.');

%% 3. Battery Pack Specifications (48V Nominal Li-ion)
% OCV lookup table for 48V nominal Li-ion
soc_breakpoints = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
voc_values      = [40.0, 42.5, 44.0, 45.5, 46.5, 47.5, 48.5, 49.5, 51.0, 52.5, 54.0];
R_internal  = 0.05;        % Internal resistance of the pack [Ohms]

%  Battery Capacity 
% 1.5 kWh target at 48V nominal = 31.25 Ah
Q_capacity  = 31.25 * 3600; % Battery capacity in Ampere-seconds (31.25 Ah pack * 3600s)
soc_initial = 0.40;         % Start the simulation at 40% SoC to test the APU kick-in

disp(' - Battery specifications updated (1.5 kWh).');

%% 4. Auxiliary Power Unit (APU) Constants
% APU Power Output
P_apu_optimal_full   = 1500; % Full-scale engine generator power [W] DOWNSIZED
eta_gen              = 0.87; % Generator electrical efficiency (87%)

% Scaled Bench-Scale Target (Scale Factor = 100)
P_apu_optimal_scaled = P_apu_optimal_full / 100; % 15W physical generator motor

disp(' - APU constants updated (1.5 kW).');

%% 5. Traction Motor Constraints (NEW)
% Motor Limits based on 14.0 kW Specification 
P_motor_max = 14000; % Peak traction motor power limit [W]
T_motor_max = 300.6; % Peak torque at wheel limit [Nm]

disp(' - Traction motor constraints loaded (14.0 kW max).');

%% 6. Energy Management System (EMS) Thresholds
soc_low_threshold  = 0.30;   % Turn engine ON at 30% SoC
soc_high_threshold = 0.80;   % Turn engine OFF at 80% SoC

% General Powertrain Efficiency
eta_mot = 0.88;              % Motor/Inverter Quasi-static efficiency (88%)

disp(' - EMS thresholds loaded.');
disp('Initialization complete. Simulink model is ready to run!');


