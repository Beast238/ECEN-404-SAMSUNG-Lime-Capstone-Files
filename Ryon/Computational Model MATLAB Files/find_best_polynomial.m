function [polynomial_coefficients, best_order] = find_best_polynomial(data, max_order, error_tolerance)
    % data: 2D array of the form [x, y], where x is the independent variable and y is the dependent variable.
    % max_order: The maximum order of polynomial to try.
    % error_tolerance: The maximum acceptable error between the fitted polynomial and the data.
    
    % Extract x and y from the input data
    x = data(:, 1);  % Independent variable (first column)
    y = data(:, 2);  % Dependent variable (second column)
    
    best_order = 0;  % Initialize the best order variable
    best_error = inf; % Initialize the best error (infinity to compare)
    polynomial_coefficients = [];  % Initialize empty polynomial coefficients
    
    for n = 1:max_order
        % Fit a polynomial of order n
        p = polyfit(x, y, n);
        
        % Evaluate the fitted polynomial at the data points (predict y values)
        y_fit = polyval(p, x);
        
        % Calculate the error (root mean square error or other metric)
        error = sqrt(mean((y - y_fit).^2));  % RMSE
        
        % Check if the error meets the tolerance
        if error <= error_tolerance
            best_order = n;  % Update the best order
            best_error = error;  % Update the best error
            polynomial_coefficients = p;  % Save the polynomial coefficients
            break;  % Exit loop if error tolerance is met
        end
    end
    
    % If no polynomial meets the error tolerance, return the best one found
    if best_order == 0
        disp('Error tolerance not met for any polynomial order.');
        disp(['Best error: ', num2str(best_error), ' for polynomial order ', num2str(best_order)]);
   
end