% =========================================================
% CityHybrid ME325 — Tractive Effort Verification
% Validates Fte equation from Project Proposal, Section 2.3
% Corresponds to Methodology Steps 2, 3 and 6
% =========================================================

clear       % clear workspace before starting
clc         % clear command window

% --- Load dependencies ---
vehicle_params                        % your L7e constants
load('colombo_cycle_verified.mat')    % loads t, v, a, dt

% =========================================================
% SECTION A — Compute each force component
% Equation: Fte = F_inertia + F_rolling + F_aero + F_slope
% =========================================================

% F_inertia = m * a
% Dominant during the 36.1% acceleration phase (per proposal)
F_inertia = m .* a;                          % [N]

% F_rolling = Crr * m * g
% Constant parasitic loss — already computed in vehicle_params
F_roll_vec = F_rolling .* ones(size(v));     % [N] constant vector

% F_aero = 0.5 * rho * Cd * A * v^2
% Proposal notes this is negligible at avg 20.3 km/h — we verify this
F_aero = 0.5 .* rho .* Cd .* A .* v.^2;    % [N]

% F_slope = m * g * sin(theta)
% Zero for flat road — Colombo is largely flat, valid assumption
F_slope = F_grade .* ones(size(v));          % [N] = 0

% --- Total tractive effort ---
Fte = F_inertia + F_roll_vec + F_aero + F_slope;   % [N]

% --- Separate traction (driving) and braking demands ---
Fte_traction = max(0, Fte);     % positive: motor must push  [N]
Fte_braking  = min(0, Fte);     % negative: braking required [N]

% =========================================================
% SECTION B — Power demand at the wheels
% =========================================================

P_wheel = Fte_traction .* v;      % [W]  instantaneous power demand
P_wheel_kW = P_wheel ./ 1000;     % [kW] for readability

% Regenerative braking power available
P_regen = abs(Fte_braking .* v);  % [W]  power recoverable during braking
P_regen_kW = P_regen ./ 1000;     % [kW]

% =========================================================
% SECTION C — Key metrics (component sizing outputs)
% =========================================================

F_peak_N      = max(Fte_traction);
P_peak_kW_val = max(P_wheel_kW);
P_avg_kW_val  = mean(P_wheel_kW(v > 0.5));   % average only when moving

% Energy over full cycle
E_total_Wh    = trapz(t, P_wheel) / 3600;    % [Wh]
E_regen_Wh    = trapz(t, P_regen) / 3600;    % [Wh]
regen_pct     = E_regen_Wh / E_total_Wh * 100;

% Force dominance check (validates proposal claim about F_inertia)
F_aero_avg_moving = mean(F_aero(v > 0.5));
F_roll_val        = F_rolling;                % constant

fprintf('\n=========================================\n')
fprintf('  CityHybrid — Tractive Effort Summary\n')
fprintf('=========================================\n')
fprintf('\n--- Force Analysis ---\n')
fprintf('Peak traction force (Fte)  : %6.1f N\n',   F_peak_N)
fprintf('Peak F_inertia             : %6.1f N\n',   max(F_inertia))
fprintf('Constant F_rolling         : %6.1f N\n',   F_roll_val)
fprintf('Avg F_aero (when moving)   : %6.1f N\n',   F_aero_avg_moving)
fprintf('F_slope                    : %6.1f N  (flat road)\n', F_grade)

fprintf('\n--- Power Analysis ---\n')
fprintf('Peak wheel power           : %6.1f kW\n',  P_peak_kW_val)
fprintf('Avg wheel power (moving)   : %6.1f kW\n',  P_avg_kW_val)
fprintf('Total energy (traction)    : %6.1f Wh\n',  E_total_Wh)
fprintf('Regen energy available     : %6.1f Wh\n',  E_regen_Wh)
fprintf('Regen recovery potential   : %6.1f %%\n',  regen_pct)
fprintf('  → Proposal target        :   30.65 %%\n')

fprintf('\n--- Proposal Claim Validation ---\n')
if F_aero_avg_moving < 0.15 * F_peak_N
    fprintf('✓ F_aero is negligible at Colombo avg speed (< 15%% of peak Fte)\n')
else
    fprintf('✗ F_aero is significant — review assumption\n')
end
if regen_pct > 25 && regen_pct < 40
    fprintf('✓ Regen potential within expected range (25–40%%)\n')
else
    fprintf('! Regen potential outside expected range — check decel profile\n')
end

fprintf('\n--- Component Sizing Targets (for Members B and C) ---\n')

% Motor sizing (add 20% design margin, account for drivetrain losses)
eta_total = 0.88 * 0.97 * 0.95;     % motor × inverter × drivetrain
P_motor_min = P_peak_kW_val * 1.20 / eta_total;
T_motor_min = F_peak_N * r_w;        % peak torque at wheel [Nm]

% Battery sizing
t_buffer_s       = 180;              % 3-min buffer without ICE
E_buffer_Wh      = P_avg_kW_val * 1000 * t_buffer_s / 3600;
usable_fraction  = 0.70;             % 20%–90% SoC window
E_battery_min_Wh = E_buffer_Wh / usable_fraction * 1.20;

% ICE-genset sizing
P_genset_min = P_avg_kW_val * 1.10;  % avg demand + 10% recharge margin

fprintf('Minimum motor power        : %5.1f kW\n',  P_motor_min)
fprintf('Peak torque at wheel       : %5.1f Nm\n',  T_motor_min)
fprintf('Minimum battery capacity   : %5.0f Wh  (%.2f kWh)\n', ...
        E_battery_min_Wh, E_battery_min_Wh/1000)
fprintf('Minimum ICE-genset power   : %5.1f kW\n',  P_genset_min)
fprintf('=========================================\n\n')

% =========================================================
% SECTION D — Plots
% =========================================================

figure('Name','Tractive Effort Analysis','NumberTitle','off', ...
       'Position',[100 100 900 700])

% Plot 1: Drive cycle speed (context)
subplot(3,2,1)
plot(t, v.*3.6, 'b-', 'LineWidth', 0.8)
xlabel('Time [s]'); ylabel('Speed [km/h]')
title('Colombo Drive Cycle')
xlim([0 t(end)]); grid on

% Plot 2: Force components stacked
subplot(3,2,2)
plot(t, F_inertia,  'r-',  'LineWidth', 0.8, 'DisplayName', 'F_{inertia}')
hold on
plot(t, F_roll_vec, 'g-',  'LineWidth', 1.2, 'DisplayName', 'F_{rolling}')
plot(t, F_aero,     'b-',  'LineWidth', 0.8, 'DisplayName', 'F_{aero}')
hold off
xlabel('Time [s]'); ylabel('Force [N]')
title('Force Components')
legend('Location','northwest', 'FontSize', 7)
xlim([0 t(end)]); grid on

% Plot 3: Total tractive effort
subplot(3,2,3)
area(t,  Fte_traction, 'FaceColor', [0.2 0.6 0.9], ...
    'FaceAlpha', 0.5, 'DisplayName', 'Traction demand')
hold on
area(t, -Fte_braking,  'FaceColor', [0.9 0.4 0.2], ...
    'FaceAlpha', 0.5, 'DisplayName', 'Braking force')
hold off
xlabel('Time [s]'); ylabel('Force [N]')
title('Total Tractive Effort (F_{te})')
legend('Location','northwest', 'FontSize', 7)
xlim([0 t(end)]); grid on

% Plot 4: Wheel power demand
subplot(3,2,4)
area(t, P_wheel_kW,  'FaceColor', [0.2 0.7 0.4], ...
    'FaceAlpha', 0.6, 'DisplayName', 'Traction power')
hold on
area(t, P_regen_kW,  'FaceColor', [0.9 0.7 0.1], ...
    'FaceAlpha', 0.6, 'DisplayName', 'Regen available')
hold off
xlabel('Time [s]'); ylabel('Power [kW]')
title('Wheel Power Demand & Regen Potential')
legend('Location','northwest', 'FontSize', 7)
xlim([0 t(end)]); grid on

% Plot 5: Force dominance pie chart
subplot(3,2,5)
E_inertia_abs = trapz(t, abs(F_inertia));
E_roll_abs    = trapz(t, F_roll_vec);
E_aero_abs    = trapz(t, F_aero);
pie([E_inertia_abs, E_roll_abs, E_aero_abs], ...
    {'F_{inertia}', 'F_{rolling}', 'F_{aero}'})
title('Force Contribution (integral)')
colormap(gca, [0.9 0.3 0.3; 0.3 0.8 0.3; 0.3 0.5 0.9])

% Plot 6: Cumulative energy
subplot(3,2,6)
E_cumul_trac  = cumtrapz(t, P_wheel)  ./ 3600;   % Wh
E_cumul_regen = cumtrapz(t, P_regen)  ./ 3600;   % Wh
plot(t, E_cumul_trac,  'b-', 'LineWidth', 1.2, 'DisplayName', 'Traction energy')
hold on
plot(t, E_cumul_regen, 'r-', 'LineWidth', 1.2, 'DisplayName', 'Regen energy')
hold off
xlabel('Time [s]'); ylabel('Energy [Wh]')
title('Cumulative Energy')
legend('Location','northwest', 'FontSize', 7)
xlim([0 t(end)]); grid on

sgtitle('CityHybrid ME325 — Tractive Effort Analysis', 'FontWeight', 'bold')

% =========================================================
% SECTION E — Save outputs for team
% =========================================================
save('tractive_effort_results.mat', ...
     'Fte', 'Fte_traction', 'Fte_braking', ...
     'P_wheel', 'P_wheel_kW', 'P_regen', 'P_regen_kW', ...
     'F_inertia', 'F_roll_vec', 'F_aero', ...
     'F_peak_N', 'P_peak_kW_val', 'P_avg_kW_val', ...
     'E_total_Wh', 'E_regen_Wh', 'regen_pct', ...
     'P_motor_min', 'T_motor_min', 'E_battery_min_Wh', 'P_genset_min')

fprintf('Saved: tractive_effort_results.mat\n')
fprintf('Share the sizing targets table with Members B and C.\n\n')