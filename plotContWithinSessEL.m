function plotContWithinSessEL(allData, sessionIdx, contrastLevel)
    % PLOTCONTRASTWITHINSESSION Compare early and late trials for specific contrast within a session
    %
    % This function splits the trials for a specific contrast level within a session into
    % early (first half) and late (second half) trials and compares responses.
    %
    % Inputs:
    %   allData - Master data structure
    %   sessionIdx - Session index to analyze
    %   contrastLevel - Contrast level to analyze (e.g., 20 for 20%)
    
    % Validate inputs
    if nargin < 2
        error('Session index must be specified');
    end
    
    if nargin < 3
        error('Contrast level must be specified (e.g., 20 for 20%)');
    end
    
    % Check if session exists
    if sessionIdx > length(allData)
        error('Session index exceeds available data');
    end
    
    % Find the contrast field
    contrastField = sprintf('Hits_contrast%d', contrastLevel);
    
    % Check if contrast exists in the data
    if ~isfield(allData(sessionIdx).tdtHitCont, contrastField)
        error('Contrast %d%% not found in session %d', contrastLevel, sessionIdx);
    end
    
    % Get data for the specified contrast
    contrastData = allData(sessionIdx).tdtHitCont.(contrastField);
    
    % Get time vector and zscores
    ts2 = contrastData.ts2;
    zall = contrastData.zall;
    
    % Get number of trials
    numTrials = size(zall, 1);
    
    if numTrials < 4
        error('Insufficient trials (minimum 4 needed) for contrast %d%% in session %d', contrastLevel, sessionIdx);
    end
    
    % Split trials into early and late
    earlyTrialsNum = floor(numTrials/2);
    lateTrialsNum = numTrials - earlyTrialsNum;
    
    % Early trials (first half)
    earlyTrials = zall(1:earlyTrialsNum, :);
    earlyMean = mean(earlyTrials, 1);
    earlyStdErr = std(earlyTrials, [], 1) / sqrt(earlyTrialsNum);
    
    % Late trials (second half)
    lateTrials = zall(earlyTrialsNum+1:end, :);
    lateMean = mean(lateTrials, 1);
    lateStdErr = std(lateTrials, [], 1) / sqrt(lateTrialsNum);
    
    % Get date from filename for title
    dateStr = '';
    if isfield(allData(sessionIdx), 'filename') && ~isempty(allData(sessionIdx).filename)
        filename = allData(sessionIdx).filename;
        if length(filename) >= 10
            dateStr = filename(1:10); % Extract YYYY-MM-DD
        end
    end
    
    % Create figure
    figure('Position', [50, 50, 800, 600], 'Color', 'w');
    hold on;
    
    % Plot early trials (blue)
    earlyTrialsLine = plot(ts2, earlyMean, 'b-', 'LineWidth', 2, 'DisplayName', sprintf('Early Trials (1-%d)', earlyTrialsNum));
    earlyTrialsFill = fill([ts2, fliplr(ts2)], [earlyMean+earlyStdErr, fliplr(earlyMean-earlyStdErr)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', '');
    
    % Plot late trials (red)
    lateTrialsLine = plot(ts2, lateMean, 'r-', 'LineWidth', 2, 'DisplayName', sprintf('Late Trials (%d-%d)', earlyTrialsNum+1, numTrials));
    lateTrialsFill = fill([ts2, fliplr(ts2)], [lateMean+lateStdErr, fliplr(lateMean-lateStdErr)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', '');
    
    % Add reference lines
    xline(0, '--', 'LineWidth', 1.5, 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    yline(0, '--', 'LineWidth', 1.5, 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    
    % Set plot limits and labels
    xlim([0 3]);
    
    % Calculate y limits based on data range with 20% padding
    dataMin = min([min(earlyMean-earlyStdErr), min(lateMean-lateStdErr)]);
    dataMax = max([max(earlyMean+earlyStdErr), max(lateMean+lateStdErr)]);
    dataRange = dataMax - dataMin;
    ylim([dataMin - 0.1*dataRange, dataMax + 0.2*dataRange]);
    
    % Set title and axis labels
    if ~isempty(dateStr)
        title(sprintf('Session %d (%s): %d%% Contrast Response Early vs Late Trials', sessionIdx, dateStr, contrastLevel), 'FontSize', 14, 'FontWeight', 'bold');
    else
        title(sprintf('Session %d: %d%% Contrast Response Early vs Late Trials', sessionIdx, contrastLevel), 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Z-score', 'FontSize', 12);
    set(gca, 'TickDir', 'out');
    
    % Add legend
    legend('Location', 'northeast', 'Box', 'off', 'FontSize', 10);
    grid on;
    

end