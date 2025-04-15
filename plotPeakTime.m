function plotPeakTime(allData, sessionIndices, splitByThreshold)
    % PLOTPEAKTIMEHISTOGRAM Create histograms of peak DA response times
    %
    % This function creates histograms showing the distribution of peak DA response
    % times in relation to stimulus onset (time 0), separately for CS and US windows.
    %
    % Inputs:
    %   allData - Master data structure containing session data
    %   sessionIndices - Session indices to analyze (default: all sessions)
    %   splitByThreshold - Boolean to split by above/below threshold (default: false)
    
    % Default to all sessions if not specified
    if nargin < 2 || isempty(sessionIndices)
        sessionIndices = 1:length(allData);
    end
    
    % Default to not splitting by threshold
    if nargin < 3 || isempty(splitByThreshold)
        splitByThreshold = false;
    end
    
    % Define time windows
    csWindow = [0.45, 0.6];  % CS window
    usWindow = [1, 1.6];   % US window
    
    % Define fixed bin edges for consistent histograms with larger bins
    csBinEdges = linspace(csWindow(1), csWindow(2), 10); % Fewer bins (9 bins) for CS
    usBinEdges = linspace(usWindow(1), usWindow(2), 10); % Fewer bins (9 bins) for US
    
    % Initialize arrays to store peak times
    csPeakTimes = [];
    csPeakTimesAbove = [];
    csPeakTimesBelow = [];
    
    usPeakTimes = [];
    usPeakTimesAbove = [];
    usPeakTimesBelow = [];
    
    % Process each session
    fprintf('Analyzing peak times for sessions: %s\n', num2str(sessionIndices));
    
    for sessIdx = 1:length(sessionIndices)
        sessionIdx = sessionIndices(sessIdx);
        
        % Skip if session index is invalid
        if sessionIdx > length(allData)
            warning('Session index %d exceeds available data. Skipping.', sessionIdx);
            continue;
        end
        
        % Get threshold for this session
        if isfield(allData(sessionIdx), 'psychometricFit') && isfield(allData(sessionIdx).psychometricFit, 'threshold')
            threshold = allData(sessionIdx).psychometricFit.threshold;
            fprintf('Session %d: Using threshold = %.3f\n', sessionIdx, threshold);
        else
            warning('No threshold found for session %d. Using default threshold of 0.1.', sessionIdx);
            threshold = 0.1;
        end
        
        % Get hit fields from structure
        if isfield(allData(sessionIdx), 'tdtHitCont')
            hitFields = fieldnames(allData(sessionIdx).tdtHitCont);
            contrastFields = hitFields(contains(hitFields, 'Hits_contrast'));
        else
            warning('No contrast data found for session %d. Skipping.', sessionIdx);
            continue;
        end
        
        % Process each contrast level
        for i = 1:length(contrastFields)
            % Extract contrast level from field name
            contrastStr = regexp(contrastFields{i}, '\d+', 'match');
            if isempty(contrastStr)
                continue;
            end
            contrastValue = str2double(contrastStr{1}) / 100; % Convert to proportion
            
            % Get data for this contrast
            contrastData = allData(sessionIdx).tdtHitCont.(contrastFields{i});
            if ~isfield(contrastData, 'zall') || ~isfield(contrastData, 'ts2')
                continue;
            end
            
            % Get z-scores and time vector
            zall = contrastData.zall;
            ts2 = contrastData.ts2;
            
            % Find indices for both windows
            csWindowIdx = ts2 >= csWindow(1) & ts2 <= csWindow(2);
            usWindowIdx = ts2 >= usWindow(1) & ts2 <= usWindow(2);
            
            % Process each trial
            for trialIdx = 1:size(zall, 1)
                % Get trial data
                trialData = zall(trialIdx, :);
                
                % Find CS window peak
                csData = trialData(csWindowIdx);
                csTimeVector = ts2(csWindowIdx);
                [~, csMaxIdx] = max(csData);
                csPeakTime = csTimeVector(csMaxIdx);
                
                % Store CS peak time in appropriate arrays
                csPeakTimes = [csPeakTimes; csPeakTime];
                if contrastValue > threshold
                    csPeakTimesAbove = [csPeakTimesAbove; csPeakTime];
                else
                    csPeakTimesBelow = [csPeakTimesBelow; csPeakTime];
                end
                
                % Find US window peak
                usData = trialData(usWindowIdx);
                usTimeVector = ts2(usWindowIdx);
                [~, usMaxIdx] = max(usData);
                usPeakTime = usTimeVector(usMaxIdx);
                
                % Store US peak time in appropriate arrays
                usPeakTimes = [usPeakTimes; usPeakTime];
                if contrastValue > threshold
                    usPeakTimesAbove = [usPeakTimesAbove; usPeakTime];
                else
                    usPeakTimesBelow = [usPeakTimesBelow; usPeakTime];
                end
            end
        end
    end
    
    % Check if we have data to plot
    if isempty(csPeakTimes) || isempty(usPeakTimes)
        error('No valid peak times found for any sessions.');
    end
    
    % Create histograms
    if splitByThreshold
        % Create figure with 4 subplots (2x2)
        figure('Position', [50, 50, 1200, 800], 'Color', 'w');
        
        % Plot CS peaks for above threshold
        subplot(2, 2, 1);
        histogram(csPeakTimesAbove, csBinEdges, 'FaceColor', 'blue', 'EdgeColor', 'k');
        title('CS Peaks (Above Threshold)');
        xlabel('Time (s)');
        ylabel('Count');
        xlim(csWindow);
        
        % Plot CS peaks for below threshold
        subplot(2, 2, 2);
        histogram(csPeakTimesBelow, csBinEdges, 'FaceColor', 'green', 'EdgeColor', 'k');
        title('CS Peaks (Below Threshold)');
        xlabel('Time (s)');
        ylabel('Count');
        xlim(csWindow);
        
        % Plot US peaks for above threshold
        subplot(2, 2, 3);
        histogram(usPeakTimesAbove, usBinEdges, 'FaceColor', 'blue', 'EdgeColor', 'k');
        title('US Peaks (Above Threshold)');
        xlabel('Time (s)');
        ylabel('Count');
        xlim(usWindow);
        
        % Plot US peaks for below threshold
        subplot(2, 2, 4);
        histogram(usPeakTimesBelow, usBinEdges, 'FaceColor', 'green', 'EdgeColor', 'k');
        title('US Peaks (Below Threshold)');
        xlabel('Time (s)');
        ylabel('Count');
        xlim(usWindow);
        
        % Add overall title
        if length(sessionIndices) == 1
            sgtitle(sprintf('Session %d: Peak Time Distributions (Split by Threshold)', sessionIndices), 'FontSize', 16);
        else
            sgtitle(sprintf('Sessions %s: Peak Time Distributions (Split by Threshold)', num2str(sessionIndices)), 'FontSize', 16);
        end
    else
        % Create figure with 2 subplots (1x2)
        figure('Position', [50, 50, 1200, 500], 'Color', 'w');
        
        % Plot CS peaks (all contrasts)
        subplot(1, 2, 1);
        histogram(csPeakTimes, csBinEdges, 'FaceColor', 'blue', 'EdgeColor', 'k');
        title('CS Peaks (All Contrasts)');
        xlabel('Time (s)');
        ylabel('Count');
        xlim(csWindow);
        
        % Plot US peaks (all contrasts)
        subplot(1, 2, 2);
        histogram(usPeakTimes, usBinEdges, 'FaceColor', 'red', 'EdgeColor', 'k');
        title('US Peaks (All Contrasts)');
        xlabel('Time (s)');
        ylabel('Count');
        xlim(usWindow);
        
        % Add overall title
        if length(sessionIndices) == 1
            sgtitle(sprintf('Session %d: Peak Time Distributions', sessionIndices), 'FontSize', 16);
        else
            sessionStr = num2str(sessionIndices);
            if length(sessionIndices) > 10
                sessionStr = [num2str(sessionIndices(1)) '-' num2str(sessionIndices(end))];
            end
            sgtitle(sprintf('Sessions %s: Peak Time Distributions', sessionStr), 'FontSize', 16);
        end
    end
    
    % Save the figure
    savePath = fullfile(pwd, 'figures');
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    
    % Create filename
    if length(sessionIndices) == 1
        baseFilename = sprintf('Session%d_PeakTimeHistogram', sessionIndices);
    else
        baseFilename = 'MultiSession_PeakTimeHistogram';
    end
    
    if splitByThreshold
        figFilename = [baseFilename '_Split.png'];
    else
        figFilename = [baseFilename '.png'];
    end
    
    fullFilePath = fullfile(savePath, figFilename);
    print(gcf, fullFilePath, '-dpng', '-r300');
    fprintf('Figure saved to: %s\n', fullFilePath);
    
    % Print basic statistics
    fprintf('\n=== Peak Time Statistics ===\n');
    fprintf('CS Window: Mean = %.3f s, Median = %.3f s, n = %d\n', mean(csPeakTimes), median(csPeakTimes), length(csPeakTimes));
    fprintf('US Window: Mean = %.3f s, Median = %.3f s, n = %d\n', mean(usPeakTimes), median(usPeakTimes), length(usPeakTimes));
    
    % Fit normal distribution and get parameters
    % CS peaks
    [muCS, sigmaCS] = normfit(csPeakTimes);
    fprintf('CS Peak Normal Fit: μ = %.3f, σ = %.3f\n', muCS, sigmaCS);
    
    % US peaks
    [muUS, sigmaUS] = normfit(usPeakTimes);
    fprintf('US Peak Normal Fit: μ = %.3f, σ = %.3f\n', muUS, sigmaUS);
end