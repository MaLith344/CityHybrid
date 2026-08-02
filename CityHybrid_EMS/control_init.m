
% CityHybrid ME325 - Master Initialization Script
% Series Hybrid Three-Wheeler (Tuk-Tuk)

clear; clc;

%% 1. Drive Cycle & Acceleration Profile Processing
raw_data = readmatrix('colombo_clean.csv');
valid_data = raw_data(raw_data(:,1) >= 0, :);
[time_sec, unique_indices] = unique(valid_data(:, 1));
speed_kmh = valid_data(unique_indices, 2);
time_sec(1) = 0;

num_loops = 4;
time_looped  = time_sec(:);
speed_looped = speed_kmh(:);
for i = 2:num_loops
    time_looped  = [time_looped; time_sec(2:end) + time_looped(end)]; %#ok<AGROW>
    speed_looped = [speed_looped; speed_kmh(2:end)]; %#ok<AGROW>
end

dt_cycle = 0.1;
t_uniform = (0:dt_cycle:time_looped(end))';
speed_resampled = interp1(time_looped, speed_looped, t_uniform, 'pchip');

poly_order   = 2;
frame_length = 15;
speed_smooth = sgolayfilt(speed_resampled, poly_order, frame_length);

v_ms  = speed_smooth / 3.6;
a_max =  1.5;
a_min = -2.0;

for k = 2:length(v_ms)
    a_inst = (v_ms(k) - v_ms(k-1)) / dt_cycle;
    if a_inst > a_max
        v_ms(k) = v_ms(k-1) + a_max * dt_cycle;
    elseif a_inst < a_min
        v_ms(k) = v_ms(k-1) + a_min * dt_cycle;
    end
end

speed_final = max(v_ms * 3.6, 0);
colombo_drive_cycle = timeseries(speed_final, t_uniform);

% Pre-compute acceleration profile (bypasses Simulink Derivative block)
v_ms_final    = speed_final / 3.6;
a_raw         = gradient(v_ms_final, dt_cycle);
a_smooth      = sgolayfilt(a_raw, poly_order, frame_length);
a_clamped     = max(min(a_smooth, a_max), a_min);
accel_profile = timeseries(a_clamped, t_uniform);

%% 2. Vehicle Physical Parameters
m     = 450;      % Mass [kg]
km    = 1.08;     % Rotational inertia factor
g     = 9.81;     % Gravity [m/s^2]
Cd    = 0.45;     % Drag coefficient
A     = 1.8;      % Frontal area [m^2]
rho   = 1.225;    % Air density [kg/m^3]
Crr   = 0.015;    % Rolling resistance coefficient
r_w   = 0.265;    % Wheel radius [m]
theta = 0;        % Road grade [rad]

F_rolling = Crr * m * g;
F_grade   = m * g * sin(theta);

%% 3. Battery Pack & BMS Boundaries (48V / 1.2 kWh LiFePO4)
soc_breakpoints = [0.00, 0.05, 0.10, 0.15, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.85, 0.90, 0.95, 1.00];
voc_values      = [37.5,  41.0,  44.0,  46.5,  48.0,  48.3, 48.6,  48.9,  49.2,  49.5,  49.8,  50.1, 50.8,  52.2,  54.75];

E_battery   = 1200;                  % Energy [Wh]
V_nominal   = 48;                    % Nominal Voltage [V]
Ah_capacity = E_battery / V_nominal; % Capacity [Ah]
Q_capacity  = Ah_capacity * 3600;    % Capacity [As]

R_internal  = 0.012;                 % Internal resistance [Ohm]
soc_initial = 0.80;                  % Initial SoC

V_bus_min_bms = 45.0;
V_bus_max_bms = 54.0;
soc_min_bms   = 0.15;
soc_max_bms   = 0.95;

%% 4. Auxiliary Power Unit (APU) & Engine Parameters
eta_gen              = 0.87;
P_apu_elec_target    = 2500;
P_apu_optimal_full   = P_apu_elec_target / eta_gen;
P_apu_optimal_scaled = P_apu_optimal_full / 100;

t_start    = 2.0;                    % Engine start delay [s]
BSFC       = 280;                    % Fuel consumption [g/kWh]
rho_petrol = 740;                    % Fuel density [g/L]

%% 5. EMS Control, Filtering & Motor Constraints
soc_low_threshold  = 0.30;           % APU ON threshold
soc_high_threshold = 0.80;           % APU OFF threshold

eta_motor = 0.88;
eta_mot   = eta_motor;
k_regen   = 0.80;
K_regen   = eta_motor * k_regen;

tau_current_filter = 0.05;           % Current filter time constant [s]

P_motor_max      = 12000;            % Peak motor power [W]
T_motor_max      = 300.6;            % Peak torque [Nm]
P_regen_max_full = -3000;            % Max regen power [W]

disp('Initialization complete. Workspace parameters loaded.');