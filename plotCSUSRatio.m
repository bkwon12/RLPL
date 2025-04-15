function plotCSUSRatio(allData, sessionIndices, separateFigures)
    % PLOTCSUSRATIO Plot the ratio of CS/US dopamine signal by contrast
    %
    % This function calculates and plots the ratio between CS-evoked and US-evoked 
    % dopamine responses across different contrast levels. A ratio > 1 indicates 
    % CS-driven responses dominate, while < 1 indicates US-driven responses dominate,
    % illustrating reward prediction error principles.
    %
    % Inputs:
    %   allData - Master data structure containing session data
    %   sessionIndices - Session indices to analyze, can be a single value or array
    %                   (default: first session)
    %   separateFigures - Boolean flag to create separate figures for each session
    %                    (default: false - combines sessions on one plot)
    
    % Default to first session if not specified
    if nargin < 2 || isempty(sessionIndices)
        sessionIndices = 1;
    end
    
    % Default to combined plot if not specified
    if nargin < 3 || isempty(separateFigures)
        separateFigures = false;
    end
    
    % Define time windows for CS and US responses
    csWindow = [0.05, 0.6];   % Early/CS window
    usWindow = [0.9, 1.5];    % Late/US window
    
    % For separate figures mode, process each session individually
    if separateFigures && length(sessionIndices) > 1
        fprintf('Creating separate figures for each session...\n');
        for i = 1:length(sessionIndices)
            % Call the function recursively for each session with separateFigures=false
            plotCSUSRatio(allData, sessionIndices(i), false);
        end
        return;
    end
    
    % Create figure - increased height for elongated y-axis
    figure('Position', [50, 50, 900, 800], 'Color', 'w');
    
    % Create arrays to store data across sessions
    allContrastValues = [];
    allRatios = [];
    allRatioErrors = [];
    allSessionLabels = [];
    
    % Process each session
    for sessIdx = 1:length(sessionIndices)
        sessionIdx = sessionIndices(sessIdx);
        
        % Skip if session index is invalid
        if sessionIdx > length(allData)
            warning('Session index %d exceeds available data. Skipping.', sessionIdx);
            continue;
        end
        
        % Get contrast fields for this session
        if isfield(allData(sessionIdx), 'tdtHitCont')
            fields = fieldnames(allData(sessionIdx).tdtHitCont);
            contrastFields = fields(contains(fields, 'Hits_contrast'));
        else
            warning('No contrast data found for session %d. Skipping.', sessionIdx);
            continue;
        end
        
        % Initialize arrays to store data for this session
        sessionContrastValues = [];
        sessionCSUSRatios = [];
        sessionCSUSRatioErrors = [];
        
        % Process each contrast level
        for i = 1:length(contrastFields)
            % Extract contrast level from field name
            contrastStr = regexp(contrastFields{i}, '\d+', 'match');
            if isempty(contrastStr)
                continue;
            end
            contrastValue = str2double(contrastStr{1});
            
            % Skip if contrast is zero (special case for log scale)
            if contrastValue == 0
                warning('Skipping contrast 0%% for session %d as it cannot be displayed on log scale.', sessionIdx);
                continue;
            end
            
            % Get data for this contrast
            contrastData = allData(sessionIdx).tdtHitCont.(contrastFields{i});
            if ~isfield(contrastData, 'zall') || ~isfield(contrastData, 'ts2')
                warning('Missing data fields for %s in session %d. Skipping.', contrastFields{i}, sessionIdx);
                continue;
            end
            
            % Get z-scores and time vector
            zall = contrastData.zall;
            ts2 = contrastData.ts2;
            
            % Find window indices
            csWindowIdx = ts2 >= csWindow(1) & ts2 <= csWindow(2);
            usWindowIdx = ts2 >= usWindow(1) & ts2 <= usWindow(2);
            
            % Calculate peak amplitudes for CS and US windows for each trial
            csPeaks = max(zall(:, csWindowIdx), [], 2);
            usPeaks = max(zall(:, usWindowIdx), [], 2);
            
            % Calculate ratio for each trial
            trialRatios = csPeaks ./ usPeaks;
            
            % Remove inf and NaN values (divide by zero or missing data)
            validIdx = isfinite(trialRatios);
            validRatios = trialRatios(validIdx);
            
            % Skip if no valid ratios
            if isempty(validRatios)
                warning('No valid CS/US ratios for contrast %d%% in session %d. Skipping.', contrastValue, sessionIdx);
                continue;
            end
            
            % Calculate mean and SEM of ratios
            meanRatio = mean(validRatios);
            semRatio = std(validRatios) / sqrt(length(validRatios));
            
            % Store data
            sessionContrastValues = [sessionContrastValues; contrastValue];
            sessionCSUSRatios = [sessionCSUSRatios; meanRatio];
            sessionCSUSRatioErrors = [sessionCSUSRatioErrors; semRatio];
        end
        
        % Skip session if no valid data
        if isempty(sessionContrastValues)
            warning('No valid contrast data found for session %d. Skipping.', sessionIdx);
            continue;
        end
        
        % Sort by contrast value
        [sessionContrastValues, sortIdx] = sort(sessionContrastValues);
        sessionCSUSRatios = sessionCSUSRatios(sortIdx);
        sessionCSUSRatioErrors = sessionCSUSRatioErrors(sortIdx);
        
        % Store data for multi-session plot
        allContrastValues = [allContrastValues; sessionContrastValues];
        allRatios = [allRatios; sessionCSUSRatios];
        allRatioErrors = [allRatioErrors; sessionCSUSRatioErrors];
        allSessionLabels = [allSessionLabels; repmat(sessionIdx, length(sessionContrastValues), 1)];
        
        % Plot for single session or individual sessions in multi-session mode
        if length(sessionIndices) == 1
            % Only plot once for a single session
            errorbar(sessionContrastValues, sessionCSUSRatios, sessionCSUSRatioErrors, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'auto');
        else
            % Plot each session with a different color
            colors = lines(length(sessionIndices));
            errorbar(sessionContrastValues, sessionCSUSRatios, sessionCSUSRatioErrors, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(sessIdx,:), 'Color', colors(sessIdx,:), 'DisplayName', sprintf('Session %d', sessionIdx));
            hold on;
        end
    end
    
    % For multiple sessions, add combined plot
    if length(sessionIndices) > 1
        % Group data by contrast
        uniqueContrasts = unique(allContrastValues);
        combinedRatios = zeros(size(uniqueContrasts));
        combinedErrors = zeros(size(uniqueContrasts));
        
        for i = 1:length(uniqueContrasts)
            contrastIndices = allContrastValues == uniqueContrasts(i);
            combinedRatios(i) = mean(allRatios(contrastIndices));
            combinedErrors(i) = std(allRatios(contrastIndices)) / sqrt(sum(contrastIndices));
        end
        
        % Plot combined across sessions
        errorbar(uniqueContrasts, combinedRatios, combinedErrors, 'ks-', 'LineWidth', 3, 'MarkerSize', 10, 'MarkerFaceColor', 'k', 'DisplayName', 'All Sessions');
        
        % Add legend
        legend('Location', 'best', 'Box', 'off');
    end
    
    % Set scale to logarithmic for x-axis
    set(gca, 'XScale', 'log');
    
    % Set the x-axis limits from 1 to 100
    xlim([1, 100]);
    
    % Custom x-tick formatting to show decimal values
    xticks([1, 2, 5, 10, 20, 50, 100]);
    xticklabels({'1', '2', '5', '10', '20', '50', '100'});
    
    fprintf('Using logarithmic scale for x-axis (1-100%).\n');
    
    % Add reference line at ratio = 1 (equal CS and US responses)
    yline(1, '--', 'CS = US', 'LineWidth', 1.5, 'Color', [0.5 0.5 0.5], 'LabelHorizontalAlignment', 'left', 'FontSize', 12);
    
    % Add labels for regions
    if ~isempty(allContrastValues)
        labelX = max(allContrastValues) * 0.7;
        text(labelX, 1.5, 'CS-driven', 'FontSize', 12, 'HorizontalAlignment', 'right', 'Color', [0 0.5 0]);
        text(labelX, 0.5, 'US-driven', 'FontSize', 12, 'HorizontalAlignment', 'right', 'Color', [0.8 0 0]);
    end
    
    % Format axes with outward ticks, increased font size
    set(gca, 'TickDir', 'out', 'FontSize', 12);
    box off;
    grid off; % Remove grid as requested
    
    % Format plot
    if length(sessionIndices) == 1
        title(sprintf('Session %d: CS/US Response Ratio by Contrast', sessionIndices), 'FontSize', 14, 'FontWeight', 'bold');
    else
        % Only in combined figure mode
        title(sprintf('CS/US Response Ratio by Contrast (Sessions %s)', num2str(sessionIndices)), 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    xlabel('Contrast (%)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('CS/US Ratio', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Set y-axis limits with spacing for elongated appearance
    if ~isempty(allRatios)
        if all(allRatios > 1)
            yMin = 0.9;
            yMax = max(allRatios + allRatioErrors)*1.1;
        elseif all(allRatios < 1)
            yMin = min(allRatios - allRatioErrors)*0.9;
            yMax = 1.1;
        else
            yRange = max(allRatios + allRatioErrors) - min(allRatios - allRatioErrors);
            yMin = min(allRatios - allRatioErrors) - 0.1*yRange;
            yMax = max(allRatios + allRatioErrors) + 0.1*yRange;
        end
        
        % Set y-limits
        ylim([yMin, yMax]);
        
        % Use fewer y-ticks to create more spacing visually
        % This makes the y-axis look elongated while keeping the same value range
        numTicks = 3; % Use fewer ticks for more spacing
        set(gca, 'YTick', linspace(.5, 1.5, 3));
    end
    
    % Print results
    fprintf('\n=== CS/US Ratio Results ===\n');
    if length(sessionIndices) == 1
        fprintf('Session %d:\n', sessionIndices);
        for i = 1:length(sessionContrastValues)
            fprintf('  Contrast %d%%: CS/US Ratio = %.2f ± %.2f\n', sessionContrastValues(i), sessionCSUSRatios(i), sessionCSUSRatioErrors(i));
        end
    else
        fprintf('Multiple Sessions:\n');
        for i = 1:length(uniqueContrasts)
            fprintf('  Contrast %d%%: CS/US Ratio = %.2f ± %.2f\n', uniqueContrasts(i), combinedRatios(i), combinedErrors(i));
        end
    end
end