filename = 'Demo Data1.csv';
data = readtable(filename);

[row, column] = size(data);
NumTrials = column / 2;

% Convert table to array for easier access
data_array = table2array(data);

% Collect all x-values across all trials to define a common x grid
all_x = [];
for i = 1:NumTrials
    x = data_array(:, 2*i - 1);
    x = x(~isnan(x)); % Remove NaNs
    all_x = [all_x; x];
end

% Define common x-grid from global min to max
x_common = linspace(min(all_x), max(all_x), 100);

% Preallocate matrix to store interpolated y-values
y_interp_matrix = zeros(NumTrials, length(x_common));

% Interpolate each trial
for i = 1:NumTrials
    x = data_array(:, 2*i - 1);
    y = data_array(:, 2*i);
    
    % Remove NaNs
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);
    
    % Interpolate using 'pchip'
    y_interp = interp1(x, y, x_common, 'pchip', 'extrap');  % 'extrap' handles out-of-bounds
    y_interp_matrix(i, :) = y_interp;
end

% Average across trials
y_avg = mean(y_interp_matrix, 1);

% Optional: Plot
figure(10); clf;
plot(x_common, y_interp_matrix, '--', 'LineWidth', 2); hold on;
plot(x_common, y_avg, 'k-', 'LineWidth', 4);
legend([arrayfun(@(i) sprintf('Trial %d', i), 1:NumTrials, 'UniformOutput', false), {'Average'}], 'FontSize', 20);
xlabel('Lime Dosage Concentration (mL/L)', 'FontSize', 20);
ylabel('Fluoride Concentration (ppm)', 'FontSize', 20);
title('Interpolated & Averaged Steady State Fluoride ', 'FontSize', 20);
grid on;


