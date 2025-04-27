% MATLAB code to calculate lime flow rate in a CSTR considering reaction rate r = k*Ca^n*F^m
% with optimization to achieve a target fluoride concentration and weight on error

function limeFlowRate = optimizeLimeFlowRate(fluorideConcentration_in_gL, Q, V, target_F_gL, k, n, m, weightError, weightFlow, limeConcentration)

   
    
    % Convert fluoride concentration from mg/L to g/L
   
    
    % Objective function to minimize the weighted error between target and steady-state fluoride concentration
    % Define the objective function
    objective = @(limeFlowRate) weightedError(limeFlowRate, fluorideConcentration_in_gL, Q, V, target_F_gL, k, n, m, limeConcentration, weightError, weightFlow);

    % Initial guess for lime flow rate (mL/s)
    initialGuess = Q/100;

    % Set lower and upper bounds
    lb = Q/1000;
    ub = 0.5*1e-3;
    ub = Q/10;
    % Create options for fmincon using the interior-point algorithm and iterative display
    options = optimoptions('fmincon', 'Display', 'iter');

    % Call fmincon to minimize the objective function subject to the bounds
    optimalLimeFlowRate = fmincon(objective, initialGuess, [], [], [], [], lb, ub, [], options);
 
    
    % Display the optimal lime flow rate
    %fprintf('The optimized lime flow rate is %.4f mL/s\n', optimalLimeFlowRate*1000);
    
    % Compute the steady-state fluoride concentration based on the optimized lime flow rate
    %C_HF_steady = computeSteadyStateConcentration(optimalLimeFlowRate, fluorideConcentration_in_gL, Q, V, k, n, m, limeConcentration);
    %fprintf('The predicted steady-state fluoride concentration is %.4f mg/L\n', C_HF_steady*1000);
    
    % Return the optimized lime flow rate
    limeFlowRate = optimalLimeFlowRate;
end

% Helper function to compute steady-state fluoride concentration in the reactor

