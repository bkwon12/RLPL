function plotDAAccSessMean(allData, addRegression)
 % PLOTLINSCORES Plot linear DA response (thresholdY) across sessions
 % Plots thresholdY values from allData.zScoreNorm3Filt.threshLinY, excluding NaN values,
 % with session numbers, mean line, and specified formatting.
 %
 % Parameters:
 %   allData - Structure array containing session data
 %   addRegression - (Optional) Boolean to add regression line and Wald test (default: false)
 
 % Set default value for addRegression if not provided
 if nargin < 2
     addRegression = false;
 end
 
 % Create figure
 figure('Position', [50 50 800 600], 'Color', 'w');
 
 % Get session count
 numSessions = length(allData);
 
 % Initialize linearValues as a structure array
 linearValues = struct();
 
 % Extract thresholdLinY values from each session
 for fileIdx = 1:numSessions
     linearValues(fileIdx).threshLinY = allData(fileIdx).zScoreNorm3Filt.threshLinY;
 end
 
 % Extract thresholdY values into a numeric array
 thresholdLinYValues = [linearValues.threshLinY];
 
 % Create array of session numbers (excluding sessions with NaN values)
 validIndices = ~isnan(thresholdLinYValues);
 validSessions = find(validIndices);
 validValues = thresholdLinYValues(validIndices);
 
 % Plot each valid session
 for i = 1:length(validSessions)
     % Plot points with no display name for legend
     scatter(validSessions(i), validValues(i), 60, 'green', 'filled', 'HandleVisibility', 'off');
     hold on;
     % Add session numbers as labels
     text(validSessions(i), validValues(i)*1.05, sprintf('%d', validSessions(i)), 'FontSize', 10);
 end
 
 % Calculate axis limits with padding
 xMin = 0.5;
 xMax = numSessions + 0.5;
 
 % Calculate mean (ignoring NaN values)
 meanLinearY = mean(validValues, 'omitnan');
 
 % Plot mean line with value in legend
 plot([xMin xMax], [meanLinearY meanLinearY], 'k--', 'LineWidth', 1.5, ...
     'DisplayName', sprintf('Mean = %.3f', meanLinearY));
 
 % Add regression line and Wald test if requested
 if addRegression
     % Prepare X data for regression (use session numbers)
     X = validSessions(:);
     % Prepare Y data for regression
     Y = validValues(:);
     
     % Perform linear regression
     % X design matrix: [ones(length(X),1), X]
     X_design = [ones(length(X),1), X];
     
     % Calculate regression coefficients (b0: intercept, b1: slope)
     b = X_design \ Y;
     
     % Calculate regression line values for plotting
     x_fit = xMin:0.1:xMax;
     y_fit = b(1) + b(2) * x_fit;
     
     % Plot regression line
     plot(x_fit, y_fit, 'r-', 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Regression: Y = %.3f + %.3f*X', b(1), b(2)));
     
     % Perform Wald test on slope (H0: slope = 0)
     % Calculate the residuals
     residuals = Y - X_design * b;
     
     % Calculate variance of the residuals
     sigma2 = sum(residuals.^2) / (length(Y) - 2);
     
     % Calculate variance-covariance matrix of the coefficients
     var_cov_b = sigma2 * inv(X_design' * X_design);
     
     % Standard error of the slope
     se_b1 = sqrt(var_cov_b(2,2));
     
     % Calculate Wald statistic for slope (H0: slope = 0)
     wald_stat = (b(2) / se_b1)^2;
     
     % Calculate p-value (chi-squared with 1 df)
     p_value = 1 - chi2cdf(wald_stat, 1);
     
     % Calculate Wald statistic for comparing to mean (H0: slope = 0)
     % For comparing with mean, we test if the regression fits better than the mean
     % Add results to plot title
     if p_value < 0.05
         significance = 'significant';
     else
         significance = 'not significant';
     end
     
     title({
         'Linear DA Response Across Sessions', 
         sprintf('Regression slope = %.3f (p = %.3f, %s)', b(2), p_value, significance)
     });
 else
     title('Linear DA Response Across Sessions');
 end
 
 % Customize plot
 xlabel('Session Number');
 ylabel('Normalized Dopamine Z-score');
 xlim([xMin xMax]);
 ylim([0 1]);
 grid on;
 legend('Location', 'best');
 set(gca, 'TickDir', 'out');
end