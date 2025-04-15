function plotContrastThresholdComp(allData, sessionIndices)
    % PLOTCONTRASTTHRESHOLDCOMP Creates heat plots and averages for hit trials
    % Split by above/below threshold contrasts
    %
    % Inputs:
    %   allData - Structure array containing processed photometry data
    %   sessionIndices - Optional array of session indices to process (default: all)
    
    % Default to all sessions if not specified
    if nargin < 2 || isempty(sessionIndices)
        sessionIndices = 1:length(allData);
    end
    
    % Initialize data structures to collect combined data across sessions
    allAboveThreshZall = [];
    allBelowThreshZall = [];
    timeVector = [];
    
    % First pass: collect data from all sessions for combined figure
    for sessIdx = 1:length(sessionIndices)
        fileIdx = sessionIndices(sessIdx);
        
        % Skip if session index is invalid
        if fileIdx > length(allData)
            warning('Session index %d exceeds available data. Skipping.', fileIdx);
            continue;
        end
        
        % Get threshold for this session
        if isfield(allData(fileIdx), 'psychometricFit') && isfield(allData(fileIdx).psychometricFit, 'threshold')
            threshold = allData(fileIdx).psychometricFit.threshold;
            fprintf('Session %d: Using threshold = %.3f\n', fileIdx, threshold);
        else
            warning('No threshold found for session %d. Using default threshold of 0.1.', fileIdx);
            threshold = 0.1;
        end
        
        % Store time vector for consistent plotting
        if isempty(timeVector) && isfield(allData(fileIdx), 'tdtAnalysis') && isfield(allData(fileIdx).tdtAnalysis, 'Hits') ...
                && isfield(allData(fileIdx).tdtAnalysis.Hits, 'ts2')
            timeVector = allData(fileIdx).tdtAnalysis.Hits.ts2;
        end
        
        % Get hit fields from structure for contrast-specific data
        if isfield(allData(fileIdx), 'tdtHitCont')
            hitFields = fieldnames(allData(fileIdx).tdtHitCont);
            contrastFields = hitFields(contains(hitFields, 'Hits_contrast'));
        else
            warning('No contrast-specific data found for session %d. Skipping.', fileIdx);
            continue;
        end
        
        % Initialize session-specific above/below threshold arrays
        aboveThreshZall = [];
        belowThreshZall = [];
        
        % Process each contrast level
        for i = 1:length(contrastFields)
            % Extract contrast level from field name
            contrastStr = regexp(contrastFields{i}, '\d+', 'match');
            if isempty(contrastStr)
                continue;
            end
            contrastValue = str2double(contrastStr{1}) / 100; % Convert to proportion
            
            % Get data for this contrast
            contrastData = allData(fileIdx).tdtHitCont.(contrastFields{i});
            if ~isfield(contrastData, 'zall') || ~isfield(contrastData, 'ts2')
                continue;
            end
            
            % Get z-score data for this contrast
            zall = contrastData.zall;
            
            % Separate trials based on contrast threshold
            if contrastValue > threshold
                aboveThreshZall = [aboveThreshZall; zall];
            else
                belowThreshZall = [belowThreshZall; zall];
            end
        end
        
        % Add to the all-sessions combined data
        allAboveThreshZall = [allAboveThreshZall; aboveThreshZall];
        allBelowThreshZall = [allBelowThreshZall; belowThreshZall];
    end
    
    % Second pass: create individual plots for each session
    for sessIdx = 1:length(sessionIndices)
        fileIdx = sessionIndices(sessIdx);
        
        % Skip if session index is invalid
        if fileIdx > length(allData)
            continue; % Already warned in first pass
        end
        
        % Get threshold for this session
        if isfield(allData(fileIdx), 'psychometricFit') && isfield(allData(fileIdx).psychometricFit, 'threshold')
            threshold = allData(fileIdx).psychometricFit.threshold;
        else
            threshold = 0.1; % Already warned in first pass
        end
        
        % Get time vector
        if isfield(allData(fileIdx), 'tdtAnalysis') && isfield(allData(fileIdx).tdtAnalysis, 'Hits') ...
                && isfield(allData(fileIdx).tdtAnalysis.Hits, 'ts2')
            ts2 = allData(fileIdx).tdtAnalysis.Hits.ts2;
        else
            warning('No time vector found for session %d. Skipping.', fileIdx);
            continue;
        end
        
        % Get hit fields from structure for contrast-specific data
        if isfield(allData(fileIdx), 'tdtHitCont')
            hitFields = fieldnames(allData(fileIdx).tdtHitCont);
            contrastFields = hitFields(contains(hitFields, 'Hits_contrast'));
        else
            continue; % Already warned in first pass
        end
        
        % Initialize session-specific above/below threshold arrays
        aboveThreshZall = [];
        belowThreshZall = [];
        
        % Process each contrast level
        for i = 1:length(contrastFields)
            % Extract contrast level from field name
            contrastStr = regexp(contrastFields{i}, '\d+', 'match');
            if isempty(contrastStr)
                continue;
            end
            contrastValue = str2double(contrastStr{1}) / 100; % Convert to proportion
            
            % Get data for this contrast
            contrastData = allData(fileIdx).tdtHitCont.(contrastFields{i});
            if ~isfield(contrastData, 'zall') || ~isfield(contrastData, 'ts2')
                continue;
            end
            
            % Get z-score data for this contrast
            zall = contrastData.zall;
            
            % Separate trials based on contrast threshold
            if contrastValue > threshold
                aboveThreshZall = [aboveThreshZall; zall];
            else
                belowThreshZall = [belowThreshZall; zall];
            end
        end
        
        % Skip if no data for either category
        if isempty(aboveThreshZall) && isempty(belowThreshZall)
            warning('No valid data found for session %d. Skipping.', fileIdx);
            continue;
        end
        
        % Get session date if available
        dateStr = '';
        if isfield(allData(fileIdx), 'filename')
            filename = allData(fileIdx).filename;
            if length(filename) >= 10
                dateStr = filename(1:10); % Extract YYYY-MM-DD
            end
        end
        
        % Create single-session figure
        createContrastCompFigure(ts2, aboveThreshZall, belowThreshZall, fileIdx, threshold, dateStr);
    end
    
    % Create combined figure across all sessions if we have data
    if ~isempty(allAboveThreshZall) || ~isempty(allBelowThreshZall)
        % Check if we have a valid time vector
        if isempty(timeVector)
            warning('No valid time vector found for combined plot.');
            return;
        end
        
        % Create the combined figure
        createContrastCompFigure(timeVector, allAboveThreshZall, allBelowThreshZall, sessionIndices, NaN, 'Combined');
    else
        warning('No valid data found for any session.');
    end
end

function createContrastCompFigure(ts2, aboveThreshZall, belowThreshZall, sessionIdx, threshold, dateStr)
    % Helper function to create individual figures
    
    % Get number of trials
    numAboveTrials = size(aboveThreshZall, 1);
    numBelowTrials = size(belowThreshZall, 1);
    totalTrials = numAboveTrials + numBelowTrials;
    
    % Skip if no data
    if totalTrials == 0
        return;
    end
    
    % Combine data for heatmap
    combinedZall = [aboveThreshZall; belowThreshZall];
    
    % Create figure with specific size
    if length(sessionIdx) == 1
        figTitle = sprintf('Session %d: Above vs Below Threshold Comparison', sessionIdx);
        if ~isempty(dateStr) && ~strcmpi(dateStr, 'Combined')
            figTitle = sprintf('Session %d (%s): Above vs Below Threshold Comparison', sessionIdx, dateStr);
        end
    else
        figTitle = 'All Sessions: Above vs Below Threshold Comparison';
        if ~isempty(dateStr) && strcmpi(dateStr, 'Combined')
            figTitle = 'All Sessions Combined: Above vs Below Threshold Comparison';
        end
    end
    
    % Create figure
    fig = figure('Name', figTitle);
    fig.Position = [50 50 1200 630];
    
    % Create overall title
    if length(sessionIdx) == 1 && ~isnan(threshold)
        sgtitle(sprintf('%s (Threshold = %.3f)', figTitle, threshold), 'FontSize', 16, 'FontWeight', 'bold');
    else
        sgtitle(figTitle, 'FontSize', 16, 'FontWeight', 'bold');
    end
    
    % Define subplot positions
    pos1 = [0.1 0.15 0.35 0.75];
    pos2 = [0.55 0.15 0.35 0.75];
    
    % Plot combined heatmap
    subplot('Position', pos1)
    imagesc(ts2, 1:totalTrials, combinedZall);
    hold on
    
    % Add separation line between above and below threshold trials
    if numAboveTrials > 0 && numBelowTrials > 0
        line([min(ts2) max(ts2)], [numAboveTrials numAboveTrials], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 2)
    end
    
    % Configure y-ticks for large datasets - FIXED TO AVOID ERROR
    if totalTrials > 80
        tickStep = floor(totalTrials / 8); % Create approximately 8 ticks
    else
        tickStep = 10; % Default for smaller datasets
    end
    
    % Set up y-ticks - FIXED TO ENSURE MONOTONICALLY INCREASING VALUES
    if numAboveTrials > 0
        yticks_above = 1:tickStep:numAboveTrials;
        if isempty(yticks_above) || yticks_above(end) < numAboveTrials
            yticks_above = [yticks_above, numAboveTrials];
        end
        ylabels_above = cellstr(num2str(yticks_above'));
    else
        yticks_above = [];
        ylabels_above = {};
    end
    
    if numBelowTrials > 0
        below_numbers = 1:tickStep:numBelowTrials;
        if isempty(below_numbers) || below_numbers(end) < numBelowTrials
            below_numbers = [below_numbers, numBelowTrials];
        end
        yticks_below = numAboveTrials + below_numbers;
        ylabels_below = cellstr(num2str(below_numbers'));
    else
        yticks_below = [];
        ylabels_below = {};
    end
    
    % Combine ticks, ensuring they're monotonically increasing
    all_yticks = sort([yticks_above, yticks_below]);
    all_ylabels = {};
    for i = 1:length(all_yticks)
        if ismember(all_yticks(i), yticks_above)
            idx = find(yticks_above == all_yticks(i));
            all_ylabels{i} = ylabels_above{idx};
        else
            idx = find(yticks_below == all_yticks(i));
            all_ylabels{i} = ylabels_below{idx};
        end
    end
    
    % Apply ticks
    set(gca, 'YTick', all_yticks);
    set(gca, 'YTickLabel', all_ylabels);
    
    % Configure colormap
    colormap('jet')
    cb = colorbar('east');
    cb.Position = [0.465 0.15 0.02 0.75];
    cb.TickDirection = 'out';
    cb.AxisLocation = 'out';
    
    % Set color limits like in the pasted function
    peakValue = max([max(aboveThreshZall(:)), max(belowThreshZall(:))]);
    caxis([1.3 peakValue]);
    
    % Set x-axis limits to show -3 to 3 seconds
    xlim([-3 3]);
    
    % Add labels
    title(sprintf('Z-Score Heat Plot: Above (%d) and Below (%d) Threshold', numAboveTrials, numBelowTrials));
    ylabel('Trials', 'FontSize', 12);
    xlabel('Time, s', 'FontSize', 12);
    
    % Plot averaged data
    subplot('Position', pos2)
    set(gca, 'TickDir', 'out')
    hold on;
    
    % Calculate smoothed averages - using a moving average filter
    windowSize = 15; % Adjust for more or less smoothing
    
    % Plot above threshold average (if we have data)
    if numAboveTrials > 0
        % Calculate mean and error
        aboveMean = mean(aboveThreshZall);
        aboveMeanSmooth = movmean(aboveMean, windowSize);
        aboveError = std(aboveThreshZall) / sqrt(numAboveTrials); % SEM
        aboveErrorSmooth = movmean(aboveError, windowSize);
        
        XX = [ts2, fliplr(ts2)];
        YY = [aboveMeanSmooth-aboveErrorSmooth, fliplr(aboveMeanSmooth+aboveErrorSmooth)];
        
        % Plot fill first
        h1 = fill(XX, YY, 'b');
        set(h1, 'facealpha', .25, 'edgecolor', 'none', 'HandleVisibility', 'off') % Hide from legend
        
        % Then plot line
        hPlot1 = plot(ts2, aboveMeanSmooth, 'color', [0, 0.4470, 0.7410], 'LineWidth', 3);
    else
        hPlot1 = [];
    end
    
    % Plot below threshold average (if we have data)
    if numBelowTrials > 0
        % Calculate mean and error
        belowMean = mean(belowThreshZall);
        belowMeanSmooth = movmean(belowMean, windowSize);
        belowError = std(belowThreshZall) / sqrt(numBelowTrials); % SEM
        belowErrorSmooth = movmean(belowError, windowSize);
        
        XX = [ts2, fliplr(ts2)];
        YY = [belowMeanSmooth-belowErrorSmooth, fliplr(belowMeanSmooth+belowErrorSmooth)];
        
        % Plot fill first
        h2 = fill(XX, YY, 'g');
        set(h2, 'facealpha', .25, 'edgecolor', 'none', 'HandleVisibility', 'off') % Hide from legend
        
        % Then plot line
        hPlot2 = plot(ts2, belowMeanSmooth, 'color', [0.4660, 0.6740, 0.1880], 'LineWidth', 3);
    else
        hPlot2 = [];
    end
    
    % Add reference lines
    line([min(ts2) max(ts2)], [0 0], 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1);
    ylims = get(gca, 'YLim');
    line([0 0], ylims, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1);
    
    % Set x-axis limits to show -3 to 3 seconds
    xlim([-3 3]);
    
    % Add legend for just the lines
    legendItems = {};
    legendHandles = [];
    
    if ~isempty(hPlot1)
        legendItems{end+1} = 'Above Threshold';
        legendHandles = [legendHandles, hPlot1];
    end
    
    if ~isempty(hPlot2)
        legendItems{end+1} = 'Below Threshold';
        legendHandles = [legendHandles, hPlot2];
    end
    
    if ~isempty(legendHandles)
        legend(legendHandles, legendItems, 'Location', 'northeast', 'FontSize', 12)
    end
    
    % Keep y-axis automatic but ensure x-axis is fixed
    xlabel('Time, s', 'FontSize', 12)
    ylabel('Z-score', 'FontSize', 12)
    title('Averaged Z-Score: Above vs Below Threshold');
end