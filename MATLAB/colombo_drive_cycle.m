% =========================================================
% CityHybrid ME325 — Colombo Drive Cycle Loader
% Source: Galgamuwa et al. (2016), Journal of Advanced Transportation
% Pre-processed: sorted, cleaned, resampled to 1-second grid
% =========================================================

% --- Load clean CSV ---
raw = readmatrix('colombo_drive_cycle.csv');   % skip header automatically

t  = raw(:, 1);            % time [s], integer 0,1,2,...,1203
v  = raw(:, 2) ./ 3.6;    % speed converted from km/h to m/s

dt = 1;                    % time step [s]

% --- Acceleration ---
a = [0; diff(v) / dt];    % [m/s^2], prepend 0 at t=0

% --- KPI verification ---
avg_kmh   = mean(v) * 3.6;
max_kmh   = max(v)  * 3.6;
idle_pct  = sum(v.*3.6 < 0.5)                       / length(v) * 100;
accel_pct = sum(diff(v.*3.6, 1, 1) >  0.15)         / length(v) * 100;
decel_pct = sum(diff(v.*3.6, 1, 1) < -0.15)         / length(v) * 100;
cruise_pct = 100 - idle_pct - accel_pct - decel_pct;

fprintf('\n=== Colombo Drive Cycle — Verified ===\n')
fprintf('Duration       : %d s\n',    t(end))
fprintf('Average speed  : %.1f km/h  (target: 20.3)\n', avg_kmh)
fprintf('Max speed      : %.1f km/h\n', max_kmh)
fprintf('Idle time      : %.1f %%     (target: 20.5)\n', idle_pct)
fprintf('Acceleration   : %.1f %%     (target: 36.1)\n', accel_pct)
fprintf('Deceleration   : %.1f %%     (target: 30.65)\n', decel_pct)
fprintf('Cruise         : %.1f %%     (target: 12.75)\n', cruise_pct)

% --- Plot 1: Speed profile ---
figure('Name','Colombo Drive Cycle','NumberTitle','off')

subplot(2,1,1)
plot(t, v.*3.6, 'b-', 'LineWidth', 0.9)
hold on
yline(avg_kmh, 'r--', sprintf('Avg %.1f km/h', avg_kmh), ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 8)
hold off
xlabel('Time [s]')
ylabel('Speed [km/h]')
title('Colombo Drive Cycle — Speed Profile')
xlim([0 t(end)])
ylim([0 70])
grid on

subplot(2,1,2)
plot(t, a, 'k-', 'LineWidth', 0.7)
yline(0, 'r--')
xlabel('Time [s]')
ylabel('Acceleration [m/s^2]')
title('Acceleration Profile')
xlim([0 t(end)])
grid on

% --- Save for team use ---
save('colombo_cycle_verified.mat', 't', 'v', 'a', 'dt')
fprintf('\nSaved: colombo_cycle_verified.mat\n')
fprintf('Team members load with: load(''colombo_cycle_verified.mat'')\n')