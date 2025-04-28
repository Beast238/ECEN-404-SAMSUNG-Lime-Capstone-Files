function C_HF_steady = computeSteadyStateConcentration(limeFlowRate, fluorideConcentration_in_gL, Q, V, k, n, m, limeConcentration)
    % Calculate lime concentration in the reactor (g/L)
   
    C_Ca = limeConcentration * limeFlowRate / (Q); % g/L

    % Define the mass balance equation based on reaction rate
    fun = @(C_HF) Q/V * (fluorideConcentration_in_gL - C_HF) - k * (C_Ca^n) * (C_HF^m);
    % Solve for steady-state fluoride concentration using fzero (root-finding)
    C_HF_steady = fzero(fun, [0, fluorideConcentration_in_gL]);

end

