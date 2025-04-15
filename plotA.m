function allData = plotA(allData)
    originalVisibility = get(0, 'DefaultFigureVisible');
    
    % Turn on figure visibility
    set(0, 'DefaultFigureVisible', 'on');

    for fileIdx = 1:length(allData)
        % Get date from filename
        filename = allData(fileIdx).filename;
        dateStr = filename(1:10); % Extract YYYY-MM-DD
        
        % Create single figure with title including date
        figure('Position', [50 50 1200 800], 'Color', 'w');
        sgtitle(sprintf('Session %d (%s) - %.0f%% Peak Contrast-Normalized', fileIdx, dateStr), 'FontSize', 16);
        
        % Get stored parameters for psychometric function
        threshold = allData(fileIdx).psychometricFit.threshold;
        betas = allData(fileIdx).psychometricFit.betas;
        fun = allData(fileIdx).psychometricFit.function;
        contrastValues = allData(fileIdx).psychometricFit.contrasts;
        hitRatios = allData(fileIdx).psychometricFit.hitRatios;
        validIdx = allData(fileIdx).zScoreNorm3Filt.validIdx;
        
        % Setup base colors
        baseColors = [
            0 0.4470 0.7410;    % Blue
            0.8500 0.3250 0.0980; % Red
            0.4660 0.6740 0.1880; % Green
            0.4940 0.1840 0.5560; % Purple
            0.9290 0.6940 0.1250; % Yellow
            0.3010 0.7450 0.9330; % Light blue
            0.6350 0.0780 0.1840; % Dark red
            0 0.5 0;             % Dark green
            0.75 0 0.75;         % Magenta
            1 0.4 0;             % Orange
        ];
        
        % Create color array based on number of contrasts in this session
        numContrasts = length(contrastValues);
        colors = repmat(baseColors, ceil(numContrasts/size(baseColors,1)), 1);
        colors = colors(1:numContrasts, :);

        % Get the valid colors using the same logical index as your contrasts
        validColors = colors(validIdx, :);

        % Get stored Peaks and Contrasts & filter out contrasts where there are less than 3 hits
        validContrasts = allData(fileIdx).zScoreNorm3Filt.validContrasts;
        validNormContPeaks = allData(fileIdx).zScoreNorm3Filt.validNormContPeaks;
        validHitRatios = allData(fileIdx).zScoreNorm3Filt.validHitRatios;
        
        % Find global min/max for neural plots (using raw z-scores for Plots 2 and 4)
        globalMin = inf;
        globalMax = -inf;
        
        yRange = globalMax - globalMin;
        globalMin = floor(globalMin - 0.1*yRange);
        globalMax = ceil(globalMax + 0.1*yRange);
        
        % Increase y-axis range for better separation
        yRangeExpanded = (globalMax - globalMin) * 1.5;  % 50% more range
        globalMinExpanded = globalMin - 0.25 * yRangeExpanded;
        globalMaxExpanded = globalMax + 0.25 * yRangeExpanded;
        
        %% Plot 1: Psychometric Function (Largest Contrast-Normalized)
        subplot(2, 2, 1);
        hold on;
        
        % Plot fit first WITHOUT DisplayName to keep it out of legend
        fitX = logspace(log10(0.001), log10(1), 100);
        fitY = fun(betas, fitX);
        plot(fitX, fitY, 'k-', 'LineWidth', 2, 'HandleVisibility', 'off');
        
        % Add threshold display and horizontal line at intersection
        minThresh = allData(fileIdx).bootstrap.CI(1);
        maxThresh = allData(fileIdx).bootstrap.CI(2);
        
        % Calculate y-value at threshold intersection
        thresholdY = fun(betas, threshold);
        
        % Add horizontal line at threshold intersection WITH DisplayName
        line([minThresh maxThresh], [thresholdY thresholdY], 'Color', 'k', ...
            'LineStyle', '-', 'LineWidth', 1, 'DisplayName', 'Threshold 95 C.I.');
                
        % Add threshold text at top left
        text(0.012, 0.95, sprintf('Threshold: %.3f', threshold), ...
            'FontSize', 10, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
        
        % Add scatter points and build legend with contrast percentages
        for i = 1:length(validContrasts)
            scatter(validContrasts(i), validHitRatios(i), 100, validColors(i,:), 'filled', ...
                'DisplayName', sprintf('%.0f%%', validContrasts(i)*100));
        end
        
        % Basic format for plot
        title('Psychometric Function', 'FontSize', 14);
        xlabel('Contrast', 'FontSize', 12);
        ylabel('Hit Rate', 'FontSize', 12);
        set(gca, 'XScale', 'log', 'TickDir', 'out', 'FontSize', 10, ...
           'XTick', [0.01 0.10 1]);
        % Remove grid
        grid off;
        xlim([0.01 1]);
        ylim([0 1]);
        legend('Location', 'eastoutside', 'Box', 'off');
        
        %% Plot 2: Above Threshold Neural Responses (normalized to largest contrast peak)
        subplot(2, 2, 2);
        hold on;
        legendHandles = [];
        legendLabels = {};

        % Get field names from tdtHitCont structure
        hitFields = fieldnames(allData(fileIdx).tdtHitCont);

        for idx = 1:length(hitFields)
            currentField = hitFields{idx};
            contrastNum = str2double(regexp(currentField, '\d+', 'match'));
            
            if contrastNum/100 > threshold
                % Check if field exists in zScoreNorm3Filt
                if ~isfield(allData(fileIdx).zScoreNorm3Filt, currentField)
                    % Skip to next iteration if field doesn't exist
                    continue;
                end
                
                % Get original data for trial count
                currentData = allData(fileIdx).zScoreNorm3Filt.(currentField);
                originalData = allData(fileIdx).tdtHitCont.(currentField);
                
                % Get timestamps from original data
                ts2 = originalData.ts2;
                
                % Plot the normalized data
                meanData = currentData.mean;
                zerrorData = currentData.error;
                
                % Add mean lines
                h = plot(ts2, meanData, 'Color', colors(idx,:), 'LineWidth', 2);
                legendHandles = [legendHandles h];
                legendLabels{end+1} = sprintf('%d%% (%d trials)', contrastNum, originalData.trialNum);
            end
        end

        % Add reference lines
        line([0 0], [globalMinExpanded globalMaxExpanded], 'Color', [.7 .7 .7], 'LineWidth', 1, ...
            'LineStyle', '--', 'HandleVisibility', 'off');
        line([0 3], [0 0], 'Color', [.7 .7 .7], 'LineWidth', 1, ...
            'LineStyle', '--', 'HandleVisibility', 'off');

        % Format plot
        xlim([0 3]);
        ylim([-1 1.8]);
        % Remove grid
        grid off; 
        box off;
        set(gca, 'TickDir', 'out', 'FontSize', 12);
        xlabel('Time (s)', 'FontSize', 14);
        ylabel('Normalized Z-score', 'FontSize', 14);
        title('Above Threshold Responses', 'FontSize', 14);
        legend(legendHandles, legendLabels, 'Location', 'eastoutside', 'Box', 'off');
        
%% Plot 3: Linear Regression of Peak Z-Scores (Largest Contrast-Normalized)
subplot(2, 2, 3);
hold on;

% Filter out contrast of 0 for regression
nonZeroIndices = validContrasts > 0;
nonZeroContrasts = validContrasts(nonZeroIndices);
nonZeroNormContPeaks = validNormContPeaks(nonZeroIndices);
nonZeroColors = validColors(nonZeroIndices,:);

% Fit linear regression using only non-zero contrasts
pMax = polyfit(nonZeroContrasts, nonZeroNormContPeaks, 1);
xlineMax = linspace(0, max(validContrasts), 100);
yfitMax = polyval(pMax, xlineMax);

% Plot only non-zero contrast points
for i = 1:length(nonZeroContrasts)
    scatter(nonZeroContrasts(i), nonZeroNormContPeaks(i), 100, nonZeroColors(i,:), 'filled', ...
        'DisplayName', sprintf('%.0f%%', nonZeroContrasts(i)*100));
end

% Plot regression line computed from non-zero points
plot(xlineMax, yfitMax, 'r-', 'LineWidth', 2, 'HandleVisibility', 'off');
ymin = ylim;
ymin = ymin(1);

% Calculate and plot threshold markers, extending to both axes
threshold_y_max = pMax(2) + pMax(1) * threshold; % y = mx + b at threshold
plot(threshold, threshold_y_max, 'k.', 'MarkerSize', 25, 'HandleVisibility', 'off');
plot([ymin threshold], [threshold_y_max threshold_y_max], 'k--', 'LineWidth', 1, 'HandleVisibility', 'off');
plot([threshold threshold], [ymin threshold_y_max], 'k--', 'LineWidth', 1, 'HandleVisibility', 'off');

% Add labels
text(threshold*1.1, threshold_y_max/2, sprintf('x: %.3f', threshold), ...
    'FontSize', 10, 'VerticalAlignment', 'middle');
text(threshold/2, threshold_y_max*1.1, sprintf('y: %.3f', threshold_y_max), ...
    'FontSize', 10, 'HorizontalAlignment', 'center');
allData(fileIdx).zScoreNorm3Filt.threshLinY = threshold_y_max;

% Format plot
xlabel('Contrast', 'FontSize', 12);
ylabel('Normalized Peak Z-score', 'FontSize', 12);
title('Linear Regression (Excluding 0% Contrast)', 'FontSize', 14);
xlim([0 max(validContrasts)*1.05]);
set(gca, 'TickDir', 'out');
% Remove grid
grid off;
legend('Location', 'eastoutside', 'Box', 'off');
        
        %% Plot 4: Below Threshold Responses (normalized to largest contrast peak)
        subplot(2, 2, 4);
        hold on;
        
        belowThreshLegendHandles = [];
        belowThreshLegendLabels = {};

        for idx = 1:length(hitFields)
            currentField = hitFields{idx};
            contrastNum = str2double(regexp(currentField, '\d+', 'match'));
            
            if contrastNum/100 <= threshold
                % Check if field exists in zScoreNorm3Filt
                if ~isfield(allData(fileIdx).zScoreNorm3Filt, currentField)
                    % Skip to next iteration if field doesn't exist
                    continue;
                end
                
                % Use the already normalized data from zScoreNorm3Filt
                currentData = allData(fileIdx).zScoreNorm3Filt.(currentField);
                
                % Get original data for trial count
                originalData = allData(fileIdx).tdtHitCont.(currentField);
                
                % Get timestamps from original data
                ts2 = originalData.ts2;
                
                % Plot the normalized data
                meanData = currentData.mean;
                zerrorData = currentData.error;
                
                % Add mean lines
                h = plot(ts2, meanData, 'Color', colors(idx,:), 'LineWidth', 2);
                
                % Use belowThreshLegendHandles and belowThreshLegendLabels instead of legendHandles and legendLabels
                belowThreshLegendHandles = [belowThreshLegendHandles h];
                belowThreshLegendLabels{end+1} = sprintf('%d%% (%d trials)', contrastNum, originalData.trialNum);
            end
        end

        % Add reference lines
        line([0 0], [globalMinExpanded globalMaxExpanded], 'Color', [.7 .7 .7], 'LineWidth', 1, ...
            'LineStyle', '--', 'HandleVisibility', 'off');
        line([0 3], [0 0], 'Color', [.7 .7 .7], 'LineWidth', 1, ...
            'LineStyle', '--', 'HandleVisibility', 'off');

        % Format plot
        xlim([0 3]);
        ylim([-.9 1.4]); % Use same scale as Plot 2
        % Remove grid
        grid off; 
        box off;
        set(gca, 'TickDir', 'out', 'FontSize', 12);
        xlabel('Time (s)', 'FontSize', 14);
        ylabel('Normalized Z-score', 'FontSize', 14);
        title('Below Threshold Responses', 'FontSize', 14);
        legend(belowThreshLegendHandles, belowThreshLegendLabels, 'Location', 'eastoutside', 'Box', 'off');
        
        % % Uncomment to save figures
        % Save the figure as a PNG file
        % savePath = fullfile(pwd, 'figures');  % Save to a 'figures' folder in the current directory
        % 
        % % Create the directory if it doesn't exist
        % if ~exist(savePath, 'dir')
        %     mkdir(savePath);
        % end
        % 
        % % Create a filename based on session number and date
        % figFilename = sprintf('Session_%d_%s.png', fileIdx, dateStr);
        % fullFilePath = fullfile(savePath, figFilename);
        % 
        % % Save the figure with high resolution
        % print(gcf, fullFilePath, '-dpng', '-r300');  % 300 dpi resolution
        % fprintf('Figure saved to: %s\n', fullFilePath);
    end  % End of for loop through allData
    
    % Restore original figure visibility
    set(0, 'DefaultFigureVisible', originalVisibility);
end  % End of function