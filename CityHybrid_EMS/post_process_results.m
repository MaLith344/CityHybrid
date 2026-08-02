%% Post-Simulation Fuel & Impact Metrics Analysis (Time-Step Independent)
if ~exist('BSFC', 'var'), BSFC = 280; end                % g/kWh
if ~exist('rho_petrol', 'var'), rho_petrol = 740; end    % g/L

% 1. Extract APU Data and Time Vector
if exist('APU_Cmd_log', 'var')
    apu_raw = APU_Cmd_log;
elseif exist('out', 'var') && isfield(out, 'APU_Cmd_log')
    apu_raw = out.APU_Cmd_log;
else
    error('APU_Cmd_log not found in workspace. Check To Workspace block.');
end

% 2. Dynamic Time & Signal Extraction
if isa(apu_raw, 'timeseries')
    t_sim    = apu_raw.Time;
    apu_data = apu_raw.Data;
elseif isstruct(apu_raw) && isfield(apu_raw, 'time')
    t_sim    = apu_raw.time;
    apu_data = apu_raw.signals.values;
else
    apu_data = apu_raw(:);
    if exist('tout', 'var')
        t_sim = tout;
    else
        t_sim = t_uniform; % fallback
    end
end

% Ensure arrays match dimensions
t_sim    = t_sim(:);
apu_data = apu_data(:);

% 3. Calculate Exact Integrated APU ON Duration
apu_active = double(apu_data > 0.5);
t_APU_on   = trapz(t_sim, apu_active);                  % Precise integration [s]
t_total    = t_sim(end) - t_sim(1);                     % Total elapsed time [s]

% 4. Core Impact Metrics Calculations
E_mech_Wh  = P_apu_optimal_full * t_APU_on / 3600;         % Mechanical energy [Wh]
fuel_g     = BSFC * (E_mech_Wh / 1000);                    % Fuel consumed [g]
fuel_L     = fuel_g / rho_petrol;                          % Fuel consumed [L]
dist_m     = trapz(t_uniform, speed_final / 3.6);          % Distance [m]
dist_km    = dist_m / 1000;                                % Distance [km]
fc_L100km  = (fuel_L / dist_km) * 100;                     % Fuel economy [L/100km]
CO2_g_km   = (fuel_g / dist_km) * 2.31;                    % CO2 emissions [g/km]

% 5. Print Summary Report
fprintf('\n================== SIMULATION IMPACT RESULTS ==================\n');
fprintf(' Total Distance Traveled:    %.2f km\n', dist_km);
fprintf(' APU Running Time:           %.0f s (%.1f%% of total trip)\n', ...
        t_APU_on, (t_APU_on / t_total) * 100);
fprintf(' Engine OFF (EV Mode Time):  %.0f s (%.1f%% zero local emissions)\n', ...
        t_total - t_APU_on, ((t_total - t_APU_on) / t_total) * 100);
fprintf('---------------------------------------------------------------\n');
fprintf(' Total Fuel Consumed:        %.3f Liters\n', fuel_L);
fprintf(' Equivalent Fuel Economy:    %.2f L/100km\n', fc_L100km);
fprintf(' CO2 Emission Factor:        %.1f g/km\n', CO2_g_km);
fprintf('===============================================================\n\n');