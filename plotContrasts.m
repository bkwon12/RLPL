function plotContrasts(allData, contrastValues, sessionIndices, varargin)
    % PLOTCONTRASTCOMPARISON Plot contrast responses within sessions or across sessions
    %
    % Usage:
    %   % Compare multiple contrasts in one session:
    %   plotContrastComparison(allData, [5, 15], 11)     % Compare 5% and 15% in session 11
    %   % With color selection (indices from baseColors):
    %   plotContrastComparison(allData, [5, 15], 11, [1, 3])  % Blue and Green colors
    %
    %   % Compare one contrast across multiple sessions:
    %   plotContrastComparison(allData, 20, [1, 3, 5])   % Compare 20% contrast across sessions 1, 3, 5
    %   % With color selection (indices from baseColors):
    %   plotContrastComparison(allData, 20, [1, 3, 5], [2, 5, 7])  % Red, Yellow, Dark red colors
    %
    %   % Compare multiple contrasts across multiple sessions:
    %   plotContrastComparison(allData, [5, 20], [1, 3, 5]) % Compare 5% and 20% across sessions 1, 3, 5
    
    % Input validation
    if nargin < 2
        error('Contrast values must be specified (e.g., [5, 15] for 5% and 15%)');
    end
    
    if nargin < 3
        error('Session index/indices must be specified');
    end
    
    % Ensure contrast values are in a row vector
    if ~isrow(contrastValues)
        contrastValues = contrastValues(:)';
    end
    
    % Ensure session indices are in a row vector
    if ~isrow(sessionIndices)
        sessionIndices = sessionIndices(:)';
    end
    
    % Setup base colors (same as used in plotA)
    baseColors = [
        0 0.4470 0.7410;    % 1. Blue
        0.8500 0.3250 0.0980; % 2. Red
        0.4660 0.6740 0.1880; % 3. Green
        0.4940 0.1840 0.5560; % 4. Purple
        0.9290 0.6940 0.1250; % 5. Yellow
        0.3010 0.7450 0.9330; % 6. Light blue
        0.6350 0.0780 0.1840; % 7. Dark red
        0 0.5 0;             % 8. Dark green
        0.75 0 0.75;         % 9. Magenta
        1 0.4 0;             % 10. Orange
    ];
    
    % Check if color indices are provided (4th argument)
    colorIndices = [];
    if nargin >= 4
        colorIndices = varargin{1};
        
        % Ensure colorIndices is a row vector
        if ~isrow(colorIndices)
            colorIndices = colorIndices(:)';
        end
    end
    
    % Determine mode based on input
    isSingleSession = length(sessionIndices) == 1;
    isSingleContrast = length(contrastValues) == 1;
    
    % Execute appropriate plotting mode
    if isSingleSession
        % Multiple contrasts in one session
        
        % Check if session index is valid
        sessionIdx = sessionIndices(1);
        if sessionIdx > length(allData) || sessionIdx < 1
            error('Session index %d is invalid', sessionIdx);
        end
        
        % Extract date info from filename if available
        dateStr = '';
        if isfield(allData(sessionIdx), 'filename')
            filename = allData(sessionIdx).filename;
            if length(filename) >= 10
                dateStr = filename(1:10); % Extract YYYY-MM-DD
            end
        end
        
        % Get normalization info
        normValue = '';
        if isfield(allData(sessionIdx).zScoreNorm3Filt, 'validContrasts')
            validContrasts = allData(sessionIdx).zScoreNorm3Filt.validContrasts;
            if ~isempty(validContrasts)
                normValue = sprintf('%.0f%%', max(validContrasts) * 100);
            end
        end
        
        % Check which contrasts are available and collect their data
        validContrasts = [];
        contrastData = cell(length(contrastValues), 1);
        contrastColors = zeros(length(contrastValues), 3);
        
        for i = 1:length(contrastValues)
            targetContrast = contrastValues(i);
            targetField = sprintf('Hits_contrast%d', targetContrast);
            
            if isfield(allData(sessionIdx).zScoreNorm3Filt, targetField)
                validContrasts = [validContrasts, targetContrast];
                
                % Store the data for this contrast
                contrastData{i}.mean = allData(sessionIdx).zScoreNorm3Filt.(targetField).mean;
                contrastData{i}.error = allData(sessionIdx).zScoreNorm3Filt.(targetField).error;
                contrastData{i}.ts2 = allData(sessionIdx).tdtHitCont.(targetField).ts2;
                
                % Get trial count if available
                if isfield(allData(sessionIdx).tdtHitCont.(targetField), 'trialNum')
                    contrastData{i}.trialNum = allData(sessionIdx).tdtHitCont.(targetField).trialNum;
                else
                    contrastData{i}.trialNum = size(allData(sessionIdx).tdtHitCont.(targetField).zall, 1);
                end
                
                % Assign colors - use custom color indices if provided
                if ~isempty(colorIndices) && i <= length(colorIndices)
                    colorIdx = colorIndices(i);
                    if colorIdx <= size(baseColors, 1) && colorIdx > 0
                        contrastColors(i,:) = baseColors(colorIdx,:);
                    else
                        % Fallback to default if index is out of range
                        contrastColors(i,:) = baseColors(mod(i-1, size(baseColors,1))+1, :);
                    end
                else
                    % Use default color assignment
                    contrastColors(i,:) = baseColors(mod(i-1, size(baseColors,1))+1, :);
                end
            else
                warning('Contrast %d%% not found in session %d', targetContrast, sessionIdx);
                contrastData{i} = [];
            end
        end
        
        % Check if we have valid data
        if isempty(validContrasts)
            error('No valid contrasts found in session %d', sessionIdx);
        end
        
        % Get time vector (use the first valid contrast)
        ts2 = contrastData{find(~cellfun(@isempty, contrastData), 1)}.ts2;
        
        % Create a new figure
        figure('Position', [100 100 800 600], 'Color', 'w');
        hold on;
        
        % Calculate appropriate y-limits based on data
        yMin = Inf;
        yMax = -Inf;
        
        for i = 1:length(contrastValues)
            if ~isempty(contrastData{i})
                % Get data
                meanData = contrastData{i}.mean;
                errorData = contrastData{i}.error;
                
                % Update global min/max
                yMin = min(yMin, min(meanData - errorData));
                yMax = max(yMax, max(meanData + errorData));
            end
        end
        
        % Add padding
        yRange = yMax - yMin;
        yMin = yMin - 0.1 * yRange;
        yMax = yMax + 0.1 * yRange;
        
        % Plot each contrast
        legendHandles = [];
        legendLabels = {};
        
        for i = 1:length(contrastValues)
            if ~isempty(contrastData{i})
                % Get data
                meanData = contrastData{i}.mean;
                errorData = contrastData{i}.error;
                contrast = contrastValues(i);
                trialNum = contrastData{i}.trialNum;
                
                % Plot error bands
                x_coords = [ts2, fliplr(ts2)];
                y_coords = [meanData + errorData, fliplr(meanData - errorData)];
                fill(x_coords, y_coords, contrastColors(i,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                
                % Plot main line
                h = plot(ts2, meanData, 'Color', contrastColors(i,:), 'LineWidth', 2);
                legendHandles = [legendHandles, h];
                legendLabels{end+1} = sprintf('%d%% (%d trials)', contrast, trialNum);
            end
        end
        
        % Add reference lines
        line([0 0], [yMin yMax], 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'LineStyle', '--', 'HandleVisibility', 'off');
        line([0 1.5], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'LineStyle', '--', 'HandleVisibility', 'off');
        
        % Format plot
        if ~isempty(dateStr) && ~isempty(normValue)
            title(sprintf('Session %d (%s, norm to %s)', sessionIdx, dateStr, normValue));
        elseif ~isempty(dateStr)
            title(sprintf('Session %d (%s)', sessionIdx, dateStr));
        elseif ~isempty(normValue)
            title(sprintf('Session %d (norm to %s)', sessionIdx, normValue));
        else
            title(sprintf('Session %d', sessionIdx));
        end
        
        xlabel('Time (s)');
        ylabel('Normalized Z-score');
        xlim([0 1.5]);
        ylim([yMin yMax]);
        
        % Set 0.5s interval x-ticks
        set(gca, 'XTick', 0:0.5:1.5);
        
        % Set axis properties
        set(gca, 'TickDir', 'out', 'Box', 'off');
        grid off;
        
        % Create legend
        legend(legendHandles, legendLabels, 'Location', 'northeast', 'Box', 'off');
    
    elseif isSingleContrast
        % One contrast across multiple sessions
        
        % Filter valid sessions (those that contain the target contrast)
        validSessions = [];
        targetContrast = contrastValues(1);
        
        for i = 1:length(sessionIndices)
            sessionIdx = sessionIndices(i);
            
            if sessionIdx > length(allData)
                warning('Session %d exceeds available data range. Skipping.', sessionIdx);
                continue;
            end
            
            % Check if this session has the target contrast in zScoreNorm3Filt
            targetField = sprintf('Hits_contrast%d', targetContrast);
            
            if isfield(allData(sessionIdx).zScoreNorm3Filt, targetField)
                validSessions = [validSessions, sessionIdx];
            else
                warning('Session %d does not contain contrast %d%%. Skipping.', sessionIdx, targetContrast);
            end
        end
        
        if isempty(validSessions)
            error('No valid sessions found containing contrast %d%%', targetContrast);
        end
        
        % Create a new figure
        figure('Position', [100 100 800 600], 'Color', 'w');
        hold on;
        
        % Get number of valid sessions
        numSessions = length(validSessions);
        
        % Set up colors for sessions - use custom color indices if provided
        sessionColors = zeros(numSessions, 3);
        for i = 1:numSessions
            if ~isempty(colorIndices) && i <= length(colorIndices)
                colorIdx = colorIndices(i);
                if colorIdx <= size(baseColors, 1) && colorIdx > 0
                    sessionColors(i,:) = baseColors(colorIdx,:);
                else
                    % Fallback to default if index is out of range
                    sessionColors(i,:) = baseColors(mod(i-1, size(baseColors,1))+1, :);
                end
            else
                % Use default color assignment
                sessionColors(i,:) = baseColors(mod(i-1, size(baseColors,1))+1, :);
            end
        end
        
        % Calculate appropriate y-limits based on data
        yMin = Inf;
        yMax = -Inf;
        
        for i = 1:numSessions
            sessionIdx = validSessions(i);
            
            % Get normalized mean and error data
            targetField = sprintf('Hits_contrast%d', targetContrast);
            normMeanData = allData(sessionIdx).zScoreNorm3Filt.(targetField).mean;
            normZerrorData = allData(sessionIdx).zScoreNorm3Filt.(targetField).error;
            
            % Update global min/max
            yMin = min(yMin, min(normMeanData - normZerrorData));
            yMax = max(yMax, max(normMeanData + normZerrorData));
        end
        
        % Add padding
        yRange = yMax - yMin;
        yMin = yMin - 0.1 * yRange;
        yMax = yMax + 0.1 * yRange;
        
        % Process each session
        legendHandles = [];
        legendLabels = {};
        
        for i = 1:numSessions
            sessionIdx = validSessions(i);
            
            % Get already normalized data for target contrast
            targetField = sprintf('Hits_contrast%d', targetContrast);
            
            % Get time series from original data
            ts2 = allData(sessionIdx).tdtHitCont.(targetField).ts2;
            
            % Get normalized mean and error data
            normMeanData = allData(sessionIdx).zScoreNorm3Filt.(targetField).mean;
            normZerrorData = allData(sessionIdx).zScoreNorm3Filt.(targetField).error;
            
            % Plot error bands
            x_coords = [ts2, fliplr(ts2)];
            y_coords = [normMeanData + normZerrorData, fliplr(normMeanData - normZerrorData)];
            fill(x_coords, y_coords, sessionColors(i,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            
            % Plot main line
            h = plot(ts2, normMeanData, 'Color', sessionColors(i,:), 'LineWidth', 2);
            
            % Get normalization info
            normValue = '';
            if isfield(allData(sessionIdx).zScoreNorm3Filt, 'validContrasts')
                validContrasts = allData(sessionIdx).zScoreNorm3Filt.validContrasts;
                if ~isempty(validContrasts)
                    normValue = sprintf('%.0f%%', max(validContrasts) * 100);
                end
            end
            
            % Add to legend
            legendHandles = [legendHandles, h];
            if ~isempty(normValue)
                legendLabels{end+1} = sprintf('Session %d (norm to %s)', sessionIdx, normValue);
            else
                legendLabels{end+1} = sprintf('Session %d', sessionIdx);
            end
        end
        
        % Add reference lines
        line([0 0], [yMin yMax], 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'LineStyle', '--', 'HandleVisibility', 'off');
        line([0 1.5], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'LineStyle', '--', 'HandleVisibility', 'off');
        
        % Format plot
        title(sprintf('%d%% Contrast Responses Across Sessions', targetContrast));
        xlabel('Time (s)');
        ylabel('Normalized Z-score');
        xlim([0 1.5]);
        ylim([yMin yMax]);
        
        % Set 0.5s interval x-ticks
        set(gca, 'XTick', 0:0.5:1.5);
        
        % Set axis properties
        set(gca, 'TickDir', 'out', 'Box', 'off');
        grid off;
        
        % Create legend
        legend(legendHandles, legendLabels, 'Location', 'northeast', 'Box', 'off');
    
    else
        % Multiple contrasts across multiple sessions
        
        % Create a new figure
        figure('Position', [100 100 1000 800], 'Color', 'w');
        
        % Calculate grid size
        numContrasts = length(contrastValues);
        numSessions = length(sessionIndices);
        
        % Create one subplot per contrast
        for c = 1:numContrasts
            subplot(numContrasts, 1, c);
            hold on;
            
            targetContrast = contrastValues(c);
            
            % Set up colors for sessions - use custom color indices if provided
            sessionColors = zeros(numSessions, 3);
            for i = 1:numSessions
                if ~isempty(colorIndices) && i <= length(colorIndices)
                    colorIdx = colorIndices(i);
                    if colorIdx <= size(baseColors, 1) && colorIdx > 0
                        sessionColors(i,:) = baseColors(colorIdx,:);
                    else
                        % Fallback to default if index is out of range
                        sessionColors(i,:) = baseColors(mod(i-1, size(baseColors,1))+1, :);
                    end
                else
                    % Use default color assignment
                    sessionColors(i,:) = baseColors(mod(i-1, size(baseColors,1))+1, :);
                end
            end
            
            % Calculate appropriate y-limits for this contrast
            yMin = Inf;
            yMax = -Inf;
            
            for s = 1:numSessions
                sessionIdx = sessionIndices(s);
                
                % Skip if session is invalid
                if sessionIdx > length(allData)
                    continue;
                end
                
                % Check if this session has the target contrast
                targetField = sprintf('Hits_contrast%d', targetContrast);
                
                if ~isfield(allData(sessionIdx).zScoreNorm3Filt, targetField)
                    continue;
                end
                
                % Get data
                normMeanData = allData(sessionIdx).zScoreNorm3Filt.(targetField).mean;
                normZerrorData = allData(sessionIdx).zScoreNorm3Filt.(targetField).error;
                
                % Update min/max
                yMin = min(yMin, min(normMeanData - normZerrorData));
                yMax = max(yMax, max(normMeanData + normZerrorData));
            end
            
            % Add padding
            yRange = yMax - yMin;
            yMin = yMin - 0.1 * yRange;
            yMax = yMax + 0.1 * yRange;
            
            % Process each session
            legendHandles = [];
            legendLabels = {};
            
            for s = 1:numSessions
                sessionIdx = sessionIndices(s);
                
                % Skip if session is invalid
                if sessionIdx > length(allData)
                    continue;
                end
                
                % Check if this session has the target contrast
                targetField = sprintf('Hits_contrast%d', targetContrast);
                
                if ~isfield(allData(sessionIdx).zScoreNorm3Filt, targetField)
                    continue;
                end
                
                % Get time and data
                ts2 = allData(sessionIdx).tdtHitCont.(targetField).ts2;
                normMeanData = allData(sessionIdx).zScoreNorm3Filt.(targetField).mean;
                normZerrorData = allData(sessionIdx).zScoreNorm3Filt.(targetField).error;
                
                % Plot error bands
                x_coords = [ts2, fliplr(ts2)];
                y_coords = [normMeanData + normZerrorData, fliplr(normMeanData - normZerrorData)];
                fill(x_coords, y_coords, sessionColors(s,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                
                % Plot main line
                h = plot(ts2, normMeanData, 'Color', sessionColors(s,:), 'LineWidth', 2);
                
                % Add to legend
                legendHandles = [legendHandles, h];
                legendLabels{end+1} = sprintf('Session %d', sessionIdx);
            end
            
            % Add reference lines
            line([0 0], [yMin yMax], 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'LineStyle', '--', 'HandleVisibility', 'off');
            line([0 1.5], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'LineStyle', '--', 'HandleVisibility', 'off');
            
            % Format subplot
            title(sprintf('%d%% Contrast', targetContrast));
            ylabel('Normalized Z-score');
            xlim([0 1.5]);
            ylim([yMin yMax]);
            
            % Set 0.5s interval x-ticks
            set(gca, 'XTick', 0:0.5:1.5);
            
            % Only add x-label to bottom subplot
            if c == numContrasts
                xlabel('Time (s)');
            end
            
            % Set axis properties
            set(gca, 'TickDir', 'out', 'Box', 'off');
            grid off;
            
            % Add legend to first subplot only
            if c == 1 && ~isempty(legendHandles)
                legend(legendHandles, legendLabels, 'Location', 'northeast', 'Box', 'off');
            end
        end
        
        % Add overall title
        sgtitle(sprintf('Contrast Responses Across Sessions'), 'FontSize', 14);
    end
    
    % Display color information in the console to help with selection
    fprintf('Available colors:\n');
    fprintf('1. Blue\n');
    fprintf('2. Red\n');
    fprintf('3. Green\n');
    fprintf('4. Purple\n');
    fprintf('5. Yellow\n');
    fprintf('6. Light blue\n');
    fprintf('7. Dark red\n');
    fprintf('8. Dark green\n');
    fprintf('9. Magenta\n');
    fprintf('10. Orange\n');
    
    if ~isempty(colorIndices)
        fprintf('\nUsed color indices: %s\n', mat2str(colorIndices));
    else
        fprintf('\nUsing default colors. To select custom colors, provide indices as 4th argument.\n');
        fprintf('Example: plotContrastComparison(allData, [5, 15], 11, [2, 5]) for Red and Yellow\n');
    end
end