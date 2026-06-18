% =========================================================
% CityHybrid ME325 — Vehicle Parameters (L7e Category)
% Colombo Urban Drive Cycle target
% =========================================================

% --- Vehicle physical parameters ---
m    = 550;        % total vehicle mass incl. payload [kg]
                   % L7e limit: 400 kg unladen + ~150 kg payload
g    = 9.81;       % gravitational acceleration [m/s^2]

% --- Aerodynamics ---
Cd   = 0.4;       % drag coefficient (three-wheeler, boxy shape)
A    = 2.08;        % frontal area [m^2] (smaller than a car)
rho  = 1.18;      % air density at sea level [kg/m^3]
                   % Colombo is near sea level — valid assumption

% --- Rolling resistance ---
Crr  = 0.015;      % rolling resistance (slightly higher for 3-wheelers)

% --- Wheel geometry ---
r_w  = 0.265;       % wheel radius [m] (smaller wheels typical of tuk-tuks)

% --- Road grade ---
theta = 0;         % flat road for baseline simulation [rad]
                   % Colombo is largely flat — valid for initial model

% --- Derived constant forces ---
F_rolling = Crr * m * g;          % constant rolling resistance [N]
F_grade   = m * g * sin(theta);   % slope force [N] = 0 for flat

% --- Colombo Drive Cycle KPIs ---
avg_speed_kmh  = 20.3;    % [km/h]
idle_fraction  = 0.205;   % 20.5% of cycle
accel_fraction = 0.361;   % 36.1% of cycle
decel_fraction = 0.3065;  % 30.65% of cycle — regen potential
cruise_fraction = 0.1275; % 12.75% of cycle

disp('CityHybrid vehicle parameters loaded.')