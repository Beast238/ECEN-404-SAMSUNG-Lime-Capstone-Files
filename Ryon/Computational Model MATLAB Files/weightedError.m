% Helper function to compute the weighted error between the target and steady-state fluoride concentration
function error = weightedError(limeFlowRate, fluorideConcentration_in_gL, Q, V, target_F_gL, k, n, m, limeConcentration, weightError, weightFlow)
    % Calculate steady-state fluoride concentration for given lime flow rate
    C_HF_steady = computeSteadyStateConcentration(limeFlowRate, fluorideConcentration_in_gL, Q, V, k, n, m, limeConcentration);
    
    % Compute the absolute difference from the target fluoride concentration
    diff = abs(C_HF_steady - target_F_gL); % Absolute difference
    
    % Compute the weighted error (multiply by the weight coefficient)
    
    error = weightError * diff + weightFlow*limeFlowRate ; % Weighted error
    if C_HF_steady*1000 > 65              % Heavy Penalty for being above discharge parameter
        error = error + 100000000000;
    end
end