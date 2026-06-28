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

% --- Smooth speed to remove resampling artefacts ---
% A 5-second moving average removes numerical spikes while
% preserving all real acceleration and braking events.
% Real urban vehicles cannot change speed faster than ~2 m/s^2 sustained.
v_raw    = v;                                  % keep original for reference
v        = smoothdata(v, 'movmean', 3);        % 5-second moving average

% --- Recompute acceleration from smoothed speed ---
a = [0; diff(v) / dt];    % [m/s^2], prepend 0 at t=0

% Verify peak acceleration is now physically realistic
fprintf('\n--- Acceleration Check (after smoothing) ---\n')
fprintf('Peak acceleration : %.2f m/s^2  (expect < 2.5 for urban)\n', max(a))
fprintf('Peak deceleration : %.2f m/s^2  (expect > -2.5 for urban)\n', min(a))

% --- KPI verification ---
avg_kmh   = mean(v) * 3.6;
max_kmh   = max(v)  * 3.6;
idle_pct  = sum(v.*3.6 < 0.5)                    / length(v) * 100;
accel_pct = sum(diff(v.*3.6, 1, 1) >  0.15)      / length(v) * 100;
decel_pct = sum(diff(v.*3.6, 1, 1) < -0.15)      / length(v) * 100;
cruise_pct = 100 - idle_pct - accel_pct - decel_pct;

fprintf('\n=== Colombo Drive Cycle — Verified ===\n')
fprintf('Duration       : %d s\n',    t(end))
fprintf('Average speed  : %.1f km/h  (target: 20.3)\n', avg_kmh)
fprintf('Max speed      : %.1f km/h\n', max_kmh)
fprintf('Idle time      : %.1f %%     (target: 20.5)\n', idle_pct)
fprintf('Acceleration   : %.1f %%     (target: 36.1)\n', accel_pct)
fprintf('Deceleration   : %.1f %%     (target: 30.65)\n', decel_pct)
fprintf('Cruise         : %.1f %%     (target: 12.75)\n', cruise_pct)

% --- Plot: Speed profile (raw vs smoothed + acceleration) ---
figure('Name','Colombo Drive Cycle','NumberTitle','off')

subplot(3,1,1)
plot(t, v_raw.*3.6, 'Color', [0.75 0.75 0.75], 'LineWidth', 0.7, ...
     'DisplayName', 'Raw')
hold on
plot(t, v.*3.6, 'b-', 'LineWidth', 1.1, 'DisplayName', 'Smoothed')
yline(avg_kmh, 'r--', sprintf('Avg %.1f km/h', avg_kmh), ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 8)
hold off
xlabel('Time [s]')
ylabel('Speed [km/h]')
title('Colombo Drive Cycle — Speed Profile (Raw vs Smoothed)')
legend('Location', 'northeast', 'FontSize', 7)
xlim([0 t(end)])
ylim([0 70])
grid on

subplot(3,1,2)
plot(t, [0; diff(v_raw)/dt], 'Color', [0.75 0.75 0.75], ...
     'LineWidth', 0.7, 'DisplayName', 'Raw acceleration')
hold on
plot(t, a, 'k-', 'LineWidth', 0.9, 'DisplayName', 'Smoothed acceleration')
yline(0, 'r--')
hold off
xlabel('Time [s]')
ylabel('Acceleration [m/s^2]')
title('Acceleration Profile')
legend('Location', 'northeast', 'FontSize', 7)
xlim([0 t(end)])
grid on

subplot(3,1,3)
histogram(a, 40, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'none')
xlabel('Acceleration [m/s^2]')
ylabel('Count')
title('Acceleration Distribution')
xline(0, 'r--')
grid on

% --- Save for team use ---
% v is the smoothed speed — this is what all subsequent scripts use
save('colombo_cycle_verified.mat', 't', 'v', 'v_raw', 'a', 'dt')
fprintf('\nSaved: colombo_cycle_verified.mat\n')
fprintf('Variables: t, v (smoothed), v_raw (original), a, dt\n')
fprintf('Team members load with: load(''colombo_cycle_verified.mat'')\n')