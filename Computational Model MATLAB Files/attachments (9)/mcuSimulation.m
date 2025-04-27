fluorideConcentrationIn = 250;

mcu(polynomial_coefficients, ...
     fluorideConcentrationIn, ...
     Q, V, k_avg, n_avg, m_avg, ...
     limeConcentration, targetF,...
     20, 1); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mcu(polyCoeff, fluorideIn_ppm, ...
             Q, V, k_avg, n_avg, m_avg, limeConc, targetF_ppm, ...
             simDuration, dt)
% MCU  Master‑Control‑Unit for the CSTR lime‑dosing system
%   • Takes a best‑fit polynomial (polyCoeff)
%   • Computes a start‑up lime‑flow
%   • Auto‑tunes PID by the Tyreus‑Luyben method (Ku, Pu)
%   • Runs the closed‑loop simulation
%   • Plots lime‑flow and fluoride vs. time with annotations
%
% USAGE:
%   mcu(polyCoeff, 250, Q, V, k_avg, n_avg, m_avg, limeConc, 2, 100, 0.1)
%
% DEPENDENCY:
%   computeSteadyStateConcentration(limeFlow_gps, fluorideIn_gL, Q, V, k, n, m, limeConc)

    %% 0) House‑keeping -----------------------------------------------------
    rng('shuffle');  
    errOffset_ppm = randi([-10, 10]);      % ±10 ppm measurement error
    errOffset_gL  = errOffset_ppm / 1000;   % g/L for model
    time          = 0:dt:simDuration;
    N             = numel(time);
    
    %% 1) Compute initial lime flow via polynomial --------------------------
    lime0_ml_s = max(polyval(polyCoeff, fluorideIn_ppm), 0);
    
    %% 2) Ziegler‑Nichols auto‑tune (Ki & Kd = 0 during hunt) ----------------
    Ku = findUltimateGain();
    Pu = findUltimatePeriod(Ku);
    
    Kp = 0.45 * Ku;                 % Tyreus‑Luyben P‑gain
    Ki = 0.54 * (Kp / Pu);          % 30% stronger integral
    Kd = 0;                         % no derivative
    
    %% 3) Closed‑loop simulation ---------------------------------------------
    limeFlow = zeros(1, N);  limeFlow(1) = lime0_ml_s;
    fluoride = nan(1, N);
    intErr   = 0;
    prevErr  = 0;
    
    for k = 2:N
        % plant prediction (g/L → ppm)
        Fpred_gL    = computeSteadyStateConcentration( ...
                         limeFlow(k-1)/1000, fluorideIn_ppm/1000, ...
                         Q, V, k_avg, n_avg, m_avg, limeConc);
        Fpred_ppm   = 1000*Fpred_gL + errOffset_ppm;
        fluoride(k) = Fpred_ppm;
        
        % PID control
        err     = Fpred_ppm - targetF_ppm;
        intErr  = intErr + err*dt;
        derErr  = (err - prevErr)/dt;
        
        u       = limeFlow(k-1) + Kp*err + Ki*intErr + Kd*derErr;
        limeFlow(k) = max(u, 0);
        prevErr = err;
    end
    
    %% 4) Plotting ------------------------------------------------------------
    figure(7); clf;
    t_fine = linspace(0, simDuration, 1000);
    
    % Lime Flow subplot
    subplot(2,1,1);
    plot(t_fine, interp1(time,      limeFlow, t_fine, 'spline'), 'LineWidth', 6);
    grid on; xlabel('Time (s)', 'FontSize', 15); ylabel('Lime Flow (mL/s)', 'FontSize', 15);
    title('PID‑controlled Lime Flow vs. Time', 'FontSize', 15);
    xlim([0 simDuration]);
    timeF = interp1(time(2:end), linspace(1, 100, 1000), 'spline');
    f = interp1(fluoride(2:end) ,linspace(1, 100, 1000), 'spline');
    % Fluoride subplot
    subplot(2,1,2);
    plot(timeF, f, 'LineWidth', 6);
    hold on;
    yline(targetF_ppm,'k--','Target','LabelVerticalAlignment','bottom','LineWidth',1.5);
    grid on; xlabel('Time (s)', 'FontSize', 15); ylabel('Fluoride (ppm)', 'FontSize', 15);
    title('Fluoride Concentration vs. Time', 'FontSize', 15);
    xlim([0 simDuration]);
    
    %% 5) Annotations ---------------------------------------------------------
    % Initial dose info
    txt = sprintf(['\\bfInital Dosage Rate\\rm\n', ...
               'Input Fluoride: %.2f ppm\n', ...
               'Initial Lime Flow Rate: %.4f mL/s\n'], ...
               fluorideIn_ppm, limeFlow(1));
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

txt = sprintf(['\\bfError and PID Coefficients\\rm\n', ...
               'Error: %.2f ppm\n', ...
               'Kp: %.7f\n', ...
               'Ki: %.7f\n', ...
               'Kd: %.1f\n'], ...
               errOffset_gL*1000, Kp, Ki, Kd);
% Add textbox annotation at a specific location
% Position = [x y width height], in normalized figure units (0 to 1)
annotation('textbox', [0.574 0.4 0.55 0.16], ...
           'String', txt, ...
           'FitBoxToText','on', ...
           'BackgroundColor','w', ...
           'EdgeColor','k', ...
           'FontSize', 20, ...
           'HorizontalAlignment', 'center', ...
           'VerticalAlignment', 'middle');


    
    drawnow;
    
    %% Nested helper functions ===============================================
    
    function Ku_out = findUltimateGain()
        Ktest = 1e-4;
        while Ktest < 1e2
            if causesOscillation(Ktest)
                break;
            end
            Ktest = Ktest*2;
        end
        Ku_out = Ktest;
    end

    function Pu_out = findUltimatePeriod(Ku_val)
        [~, pk] = quickTestPID(Ku_val, 0, 0);
        if numel(pk)>=2
            Pu_out = dt * mean(diff(pk));
        else
            Pu_out = dt*10;  % fallback guess
        end
    end

    function flag = causesOscillation(Kp_val)
        Fppm = quickTestPID(Kp_val,0,0);
        tail = Fppm(end - round(0.3*numel(Fppm)) + 1 : end);
        flag = peak2peak(tail) > 2;  % >2 ppm swing
    end

    function [FppmArr, peakIdx] = quickTestPID(Kp_val, Ki_val, Kd_val)
        Tshort  = min(simDuration/2, 100);
        Nshort  = ceil(Tshort/dt);
        u       = lime0_ml_s;
        FppmArr = zeros(1, Nshort);
        peakIdx = [];
        intE    = 0;
        prevE   = 0;
        for ii = 2:Nshort
            FgL      = computeSteadyStateConcentration(...
                          u/1000, fluorideIn_ppm/1000, Q, V, ...
                          k_avg, n_avg, m_avg, limeConc);
            FppmArr(ii) = 1000*FgL + errOffset_ppm;
            
            e    = FppmArr(ii) - targetF_ppm;
            intE = intE + e*dt;
            dE   = (e-prevE)/dt;
            
            u    = max(u + Kp_val*e + Ki_val*intE + Kd_val*dE, 0);
            prevE= e;
        end
        if nargout>1
            [~, peakIdx] = findpeaks(FppmArr,'MinPeakProminence',2);
        end
    end

end
