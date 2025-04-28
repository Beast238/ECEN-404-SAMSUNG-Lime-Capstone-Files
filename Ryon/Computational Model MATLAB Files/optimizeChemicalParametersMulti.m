function cost = optimizeChemicalParametersMulti(measurementFluoride, weightError, limeFlowRate, fluorideConcentration_in_gL, Q, V, x, limeConcentration)
    % Extract parameters from x vector
    k = x(1);
    n = x(2);
    m = x(3);
    
    % Compute the predicted fluoride using your model
    predictedFluoride = computeSteadyStateConcentration(limeFlowRate, fluorideConcentration_in_gL, Q, V, k, n, m, limeConcentration);
    
    % Calculate the error between the model prediction and the measurement
    error = predictedFluoride - measurementFluoride;
    
    % Define the cost function (using squared error)
    cost = weightError * error^2;
end
