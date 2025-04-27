%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS SET BEFORE SYSTEM OPERTAION
V = 10;                                                                    % Volume of reactor (L)
Q = V/1000;                                                                % Flow Rate of Wastewater (Residence time 1000s)
limeConcentration = 445;                                                   % SLS-45 Lime Concentration (CHANGE IF DILUTING) (g/L)
targetF = 30;                                                              % Target steady state fluoride concentration (ppm)

% PERFORM CALIBRATION OF CHEMICAL PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FROM EXTERNAL EXPERIMENTS
limeData = x_common;                                                       % Input lime concentration (mL/L);
steadyStateFluoride = y_avg;                                               % Resulting fluoride from input lime dosage (ppm, mg/L) 
limeFlowData = limeData * Q;                                               % Convert to flow rate (mL/s)
fluorideConcentration_in_gL = 250/1000;                                    % Initial fluoride concentration taken from experiment (g/L)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

optimalParams = zeros(length(limeFlowData), 3);                            % Initalize optimal parameters array
options = optimoptions('fmincon', 'Display', 'off');                       % Set optimization options
% Loop over each lime dosage value
for i = 1:length(limeFlowData)
    objective = @(x) optimizeChemicalParametersMulti(...
        steadyStateFluoride(i)/1000, ...                                   % Measured fluoride for this DOE point (g/L)
        1, ...                                                             % Weight error factor (CHANGE AS NEEDED)
        limeFlowData(i)*1e-3, ...                                          % Lime flow rate (converted if needed)
        fluorideConcentration_in_gL, ...                                   % Input fluoride concentration
        Q, V, x, limeConcentration);                                       % x contains [k, n, m]

    % Initial guess for [k, n, m]
    x0 = [0.0001, 1, 2];                                                   % Adjust these initial values as appropriate

    % Define lower and upper bounds for k, n, and m.
    lb = [0, 0.5, 0.5];
    ub = [0.01, 3, 3];

    % Optimize using fmincon to find the optimal [k, n, m] that minimizes the cost.
    optimalParams(i, :) = fmincon(objective, x0, [], ...
        [], [], [], lb, ub, [], options);                                  % Optimize using fmincon to find the optimal [k, n, m] that minimizes the cost.
end

% Extract optimized parameters for clarity
k_ideal = optimalParams(:, 1);
n_optimal = optimalParams(:, 2);
m_optimal = optimalParams(:, 3);

% Obtain idealized chemical parameters, removed edge cases
n_avg = mean(n_optimal(3:end-3));            
m_avg = mean(m_optimal(3:end-3));
k_avg = mean(k_ideal(3:end-3));

% Smooth parameter curves (use polynomial fit of order 3–5 depending on curvature)
p_k = polyfit(x_common, k_ideal, 4);
p_n = polyfit(x_common, n_optimal, 4);
p_m = polyfit(x_common, m_optimal, 4);

y_p_k = polyval(p_k, x_common);
y_p_n = polyval(p_n, x_common);
y_p_m = polyval(p_m, x_common);


figure(8); clf;

% --- Top Left (1,1): k_ideal
subplot(2, 2, 1);
plot(x_common(3:end-3), k_ideal(3:end-3), 'b', 'LineWidth', 5);
hold on; plot(x_common(3:end-3), y_p_k(3:end-3), 'k', 'LineWidth', 3);
ylim([k_avg-0.001 k_avg+0.001]);
title('Calibrated k vs. Lime Concentration', 'FontSize', 14);
yline(k_avg, 'k', 'label', 'k\_avg', 'LineStyle', '--', 'LineWidth', 3)
legend("Idealzed Curve", "Fitted 4th Order Polynomial", 'location', 'northeast', 'FontSize', 12);

xlabel('Lime Concentration (mL/L)', 'FontSize', 12);
ylabel('k\_ideal', 'FontSize', 12);

% --- Create an empty subplot for (1,2) just to reserve space
subplot(2, 2, 2); axis off;

% --- Place 2 mini-plots inside top-right corner of the figure manually
% Top mini-plot: n_optimal
axes('Position', [0.5 0.78 0.23 0.14]);  % [left, bottom, width, height]
plot(x_common(3:end-3), n_optimal(3:end-3), 'r', 'LineWidth', 5);
hold on; plot(x_common(3:end-3), y_p_n(3:end-3), 'k', 'LineWidth', 3);
yline(n_avg, 'k', 'label', 'n\_avg', 'LineStyle', '--', 'LineWidth', 3)
ylim([n_avg-0.4 n_avg+0.4]);

title('n\_optimal');
set(gca, 'FontSize', 8);

% Bottom mini-plot: m_optimal
axes('Position', [0.5 0.58 0.23 0.14]);  % same width, shifted lower
plot(x_common(3:end-3), m_optimal(3:end-3), 'g', 'LineWidth', 5);
hold on; plot(x_common(3:end-3), y_p_m(3:end-3), 'k', 'LineWidth', 3);
yline(m_avg, 'k', 'label', 'm\_avg', 'LineStyle', '--', 'LineWidth', 3)
ylim([m_avg-0.5 m_avg+0.5]);
xlabel("Lime Concentration (mL/L)", 'FontSize', 12); 

title('m\_optimal');
set(gca, 'FontSize', 8);


%CALIBRATION COMPLETE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PLOT TO VERIFY, RUN STEADY STATE FLUORIDE AND COMPARE TO EXPERIMENT
y_p_k = polyval(p_k, x_common);
y_p_n = polyval(p_n, x_common);
y_p_m = polyval(p_m, x_common);
fluorideConcentration_in_gL = 249/1000;  % To match with experiment
predictedFluoride = zeros(1, length(limeFlowData));
for i=1:length(predictedFluoride)
    predictedFluoride(i) = computeSteadyStateConcentration(limeFlowData(i)*1e-3, fluorideConcentration_in_gL, Q, V, y_p_k(i), y_p_n(i), y_p_m(i), limeConcentration);
end
subplot(2, 2, 3);
plot(limeData*Q, steadyStateFluoride, 'b', 'LineWidth', 5);
hold on; plot(limeData*Q, predictedFluoride*1000, 'r', 'LineWidth', 5);
xlabel("Lime Flow Rate (mL/s)", 'FontSize', 12);
ylabel("Steady State Fluoride Concentration (ppm)", 'FontSize', 12);
title("Plot of Measured Data and Calibrated Chemical Model", 'FontSize', 15);
legend("Experimental Data", "Calibrated Chemical Model", 'FontSize', 15);
xlim([0 7*Q]);


predicted_ppm = predictedFluoride * 1000;

% Pointwise percent error
percentError = abs((steadyStateFluoride(2:end-2) - predicted_ppm(2:end-2))) ./ steadyStateFluoride(2:end-2) * 100;

% Optional: summary statistics
meanPercentError = mean(percentError);
maxPercentError = max(percentError);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GENERATE POLYNOMIAL BASED ON TARGET FLUORIDE
inputFluoride = linspace(0, 1000, 100);                                    % Initalize for all possible input fluoride concentrations (ppm)
limeFlowRateArray = zeros(size(inputFluoride));                            % Initalize optimized lime flow array

weightFlow = 1*Q/0.01 * limeConcentration/445;                                                            % Weight to penalize overdosing 
weightError = 10*Q * limeConcentration/445;                                                        % Weight to penalize error to target

for i=1:length(inputFluoride)
     limeFlowRateArray(i) = optimizeLimeFlowRate(inputFluoride(i)/1000, Q, V, targetF/1000, k_avg, n_avg, m_avg, weightError*Q*100, weightFlow*Q*100, limeConcentration);
end

for i=1:length(inputFluoride)
     steadyStateFluoride(i) = computeSteadyStateConcentration(limeFlowRateArray(i), inputFluoride(i)/1000, Q, V, k_avg, n_avg, m_avg, limeConcentration);
end

max_order = 5;
error_tolerance = Q/5;
data = [inputFluoride(:), limeFlowRateArray(:)*1000];                      %Fluoride in (ppm), Lime Flow in (mL/s)
[polynomial_coefficients, best_order] = find_best_polynomial(data, max_order, error_tolerance);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PLOT TO CHECK POLYNOMIAL
%Calculate the fitted y values using the best polynomial coefficients
y_fit = polyval(polynomial_coefficients, inputFluoride);

% --- Subplot for Polynomial Fit
subplot(2, 2, 4); axis off;
axes('Position', [0.5125 0.1 0.45 0.35]);  % [left, bottom, width, height]

% Plot the actual data as blue circles
plot(inputFluoride, limeFlowRateArray*1000, 'bo', ...
     'MarkerFaceColor', 'b', 'DisplayName', 'Actual Data');

% Plot the fitted polynomial as a red line
hold on;
plot(inputFluoride, y_fit, 'r-', 'LineWidth', 2, ...
     'DisplayName', ['Fitted Polynomial (Order ', num2str(best_order), ')']);

% Add labels and title
xlabel('Input Fluoride Concentration (ppm)', 'FontSize', 12);
ylabel('Resulting Lime Flow Rate (mL/s)', 'FontSize', 12);
title('Polynomial Fit to Input Fluoride (ppm) vs. Optimized Lime Dose (mL/s)', 'FontSize', 15);
legend('Location', 'best', 'FontSize', 12);
grid on;
txt = sprintf(['\\bfPercentage Error\\rm\n', ...
               'Mean: %.2f%%\n', ...
               'Max: %.2f%%\n'], ...
               meanPercentError, maxPercentError);
% Add textbox annotation at a specific location
% Position = [x y width height], in normalized figure units (0 to 1)
annotation('textbox', [0.574 0.8 0.55 0.16], ...
           'String', txt, ...
           'FitBoxToText','on', ...
           'BackgroundColor','w', ...
           'EdgeColor','k', ...
           'FontSize', 20, ...
           'HorizontalAlignment', 'center', ...
           'VerticalAlignment', 'middle');

nCoeff   = numel(polynomial_coefficients);          % = best_order+1
polyTxt  = sprintf('\\bfPolynomial Order:\\rm  %d\n', best_order);

% Append one line per coefficient.  The highest‑order term is printed first
for k = 1:nCoeff
    idx   = best_order-(k-1);                       % exponent of x
    coeff = polynomial_coefficients(k);             % value
    polyTxt = sprintf('%s a_{%d} = %.4g\n', polyTxt, idx, coeff);
end

% Remove the very last newline so the box looks neat
polyTxt = polyTxt(1:end-1);

%% ------------------------------------------------------------------------
% 2)  Decide on a font size that will squeeze everything into the same box
% -------------------------------------------------------------------------
baseFS   = 20;                    % what you used for the %‑error box
nLines   = nCoeff + 1;             % “order” line + coefficient lines
fontSize = max(8, baseFS - (nLines-4));  % shrink 1 pt per extra line (tweak)


polyPos  = [0.75 0.55 0.20 0.23];  % [left bottom width height] in figure units
annotation('textbox', polyPos, ...
           'String',            polyTxt, ...
           'Interpreter',       'tex', ...
           'FontSize',          fontSize, ...
           'FitBoxToText',      'on', ...
           'BackgroundColor',   'w', ...
           'EdgeColor',         'k', ...
           'HorizontalAlignment','center', ...
           'VerticalAlignment', 'middle');

                          