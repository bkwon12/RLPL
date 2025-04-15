function plotDATraces(allData, fileIdx, sortedFields, sortedContrasts, timePeriod, medianTime, colors)
    % Function to plot dopamine traces by contrast for early or late trials
    % Inputs:
    %   allData - main data structure
    %   fileIdx - index of current file
    %   sortedFields - sorted field names for contrasts
    %   sortedContrasts - sorted contrast values
    %   timePeriod - 'early' or 'late'
    %   medianTime - time cutoff between early and late
    %   colors - color palette to use
    
    legendHandles = [];
    legendLabels = {};
    
    % Find the field with the largest number of trials to normalize
    maxPeak = -inf;
    for i = 1:length(sortedFields)
        currentField = sortedFields{i};
        if ~isfield(allData(fileIdx).tdtHitCont, currentField)
            continue;
        end
        
        currentData = allData(fileIdx).tdtHitCont.(currentField);
        if ~isfield(currentData, 'zall') || ~isfield(currentData, 'ts2')
            continue;
        end
        
        % Find peak in window
        ts2 = currentData.ts2;
        window = ts2 >= 0.45 & ts2 <= 0.6;
        meanData = mean(currentData.zall, 1);
        windowData = meanData(window);
        [peak, ~] = max(windowData);
        
        if peak > maxPeak
            maxPeak = peak;
        end
    end
    
    % Plot each contrast
    for i = 1:length(sortedFields)
        currentField = sortedFields{i};
        contrastNum = sortedContrasts(i);
        
        % Skip if field doesn't exist
        if ~isfield(allData(fileIdx).tdtHitCont, currentField)
            continue;
        end
        
        currentData = allData(fileIdx).tdtHitCont.(currentField);
        if ~isfield(currentData, 'zall') || ~isfield(currentData, 'ts2')
            continue;
        end
        
        % Get trial timestamps for this contrast
        hitField = ['hitTrials_contrast' num2str(contrastNum)];
        if ~isfield(allData(fileIdx).behavior, hitField)
            continue;
        end
        
        hitTimestamps = allData(fileIdx).behavior.(hitField);
        
        % Select early or late trials
        if strcmp(timePeriod, 'early')
            trialMask = hitTimestamps < medianTime;
        else
            trialMask = hitTimestamps >= medianTime;
        end
        
        % Skip if no trials in this period
        if sum(trialMask) < 1
            continue;
        end
        
        % Get corresponding indices in the zall data
        % This is tricky since we need to match timestamps to trials
        % For simplicity, we'll use all trials if we can't match exactly
        
        % Get time vector and z-scores
        ts2 = currentData.ts2;
        zall = currentData.zall;
        
        % If we can identify the specific trials, use those
        if size(zall, 1) == length(hitTimestamps)
            zall_filtered = zall(trialMask, :);
        else
            % Otherwise use all trials (not ideal but allows code to run)
            zall_filtered = zall;
            warning('Cannot match trial timestamps for %s - using all trials', currentField);
        end
        
        % Calculate mean and error
        meanData = mean(zall_filtered, 1) / maxPeak; % Normalize
        if size(zall_filtered, 1) > 1
            errorData = std(zall_filtered, [], 1) / sqrt(size(zall_filtered, 1)) / maxPeak;
        else
            errorData = zeros(size(meanData));
        end
        
        % Use modulo to cycle through colors for datasets with many contrasts
        colorIdx = mod(i-1, size(colors, 1)) + 1;
        
        % Plot mean line
        h = plot(ts2, meanData, 'Color', colors(colorIdx,:), 'LineWidth', 2);
        
        % Add shaded error area
        fill([ts2, fliplr(ts2)], [meanData+errorData, fliplr(meanData-errorData)], ...
            colors(colorIdx,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % Add to legend
        legendHandles = [legendHandles, h];
        legendLabels{end+1} = sprintf('%d%% (%d trials)', contrastNum, size(zall_filtered, 1));
    end
    
    % Add reference lines
    line([0 0], [-1 2], 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '--');
    line([0 3], [0 0], 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '--');
    
    % Format plot
    xlim([0 3]);
    ylim([-0.5 1.5]);
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Normalized Z-score', 'FontSize', 12);
    grid on;
    
    % Add legend if we have any traces
    if ~isempty(legendHandles)
        legend(legendHandles, legendLabels, 'Location', 'northeast', 'Box', 'off');
    end
endfunction allData = analyzeEarlyLateContrasts(allData)
    % Function to analyze contrast performance in early vs late trials
    % and display the corresponding dopamine traces
    %
    % Input: allData - structure containing processed photometry data
    % Output: allData - updated with early/late analysis results
    
    % Store original figure visibility
    originalVisibility = get(0, 'DefaultFigureVisible');
    set(0, 'DefaultFigureVisible', 'on');

    % Define color palette with 12 colors
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
        0.5 0.5 0.5;         % Gray
        0.2 0.8 0.8;         % Cyan
    ];

    % Process each dataset
    for fileIdx = 1:length(allData)
        try
            fprintf('Analyzing early vs late trials for dataset %d...\n', fileIdx);
            
            % Get date from filename
            filename = allData(fileIdx).filename;
            dateStr = filename(1:10); % Extract YYYY-MM-DD
            
            % Check if required fields exist
            if ~isfield(allData(fileIdx), 'behavior') || ~isfield(allData(fileIdx), 'tdtHitCont')
                warning('Required fields missing for dataset %d. Skipping...', fileIdx);
                continue;
            end
            
            % Get trial timestamps for all trials
            if isfield(allData(fileIdx).behavior, 'hitTrials') && ...
               isfield(allData(fileIdx).behavior, 'missTrials')
                hitTimestamps = allData(fileIdx).behavior.hitTrials;
                missTimestamps = allData(fileIdx).behavior.missTrials;
                allTimestamps = sort([hitTimestamps; missTimestamps]);
            else
                warning('Hit or miss trial data missing for dataset %d. Skipping...', fileIdx);
                continue;
            end
            
            % Check if we have enough trials
            if length(allTimestamps) < 4
                warning('Not enough trials for dataset %d. Skipping...', fileIdx);
                continue;
            end
            
            % Find median timestamp to split early vs late
            medianTime = median(allTimestamps);
            
            % Get contrast-specific fields
            fields = fieldnames(allData(fileIdx).behavior);
            hitContrastFields = fields(contains(fields, 'hitTrials_contrast'));
            missContrastFields = fields(contains(fields, 'missTrials_contrast'));
            
            % Extract contrast numbers
            contrasts = cellfun(@(x) str2double(regexp(x, '\d+', 'match')), hitContrastFields);
            [sortedContrasts, sortIdx] = sort(contrasts);
            
            % Get corresponding field names
            sortedHitFields = hitContrastFields(sortIdx);
            sortedMissFields = missContrastFields(sortIdx);
            
            % Initialize results storage
            numContrasts = length(sortedContrasts);
            earlyHits = zeros(1, numContrasts);
            earlyMisses = zeros(1, numContrasts);
            lateHits = zeros(1, numContrasts);
            lateMisses = zeros(1, numContrasts);
            earlyHitRate = zeros(1, numContrasts);
            lateHitRate = zeros(1, numContrasts);
            
            % Get early/late hit counts for each contrast
            for i = 1:numContrasts
                % Get hit and miss timestamps for this contrast
                hitField = sortedHitFields{i};
                missField = sortedMissFields{i};
                
                contrastHitTimestamps = allData(fileIdx).behavior.(hitField);
                contrastMissTimestamps = allData(fileIdx).behavior.(missField);
                
                % Count early/late hits and misses
                earlyHits(i) = sum(contrastHitTimestamps < medianTime);
                lateHits(i) = sum(contrastHitTimestamps >= medianTime);
                earlyMisses(i) = sum(contrastMissTimestamps < medianTime);
                lateMisses(i) = sum(contrastMissTimestamps >= medianTime);
                
                % Calculate hit rates
                earlyTotal = earlyHits(i) + earlyMisses(i);
                lateTotal = lateHits(i) + lateMisses(i);
                
                if earlyTotal > 0
                    earlyHitRate(i) = earlyHits(i) / earlyTotal;
                else
                    earlyHitRate(i) = NaN;
                end
                
                if lateTotal > 0
                    lateHitRate(i) = lateHits(i) / lateTotal;
                else
                    lateHitRate(i) = NaN;
                end
            end
            
            % Store the results in the allData structure
            allData(fileIdx).earlyLateAnalysis = struct(...
                'medianTime', medianTime, ...
                'contrasts', sortedContrasts, ...
                'earlyHits', earlyHits, ...
                'earlyMisses', earlyMisses, ...
                'lateHits', lateHits, ...
                'lateMisses', lateMisses, ...
                'earlyHitRate', earlyHitRate, ...
                'lateHitRate', lateHitRate);
            
            % Create figure
            figure('Position', [100 100 1200 900], 'Color', 'w');
            sgtitle(sprintf('Session %d (%s) - Early vs Late Trial Performance', fileIdx, dateStr), 'FontSize', 16);
            
            % Plot 1: Hit rates by contrast for early vs late trials
            subplot(2, 2, 1);
            hold on;
            
            % Create bar chart showing hit rates by contrast, early vs late
            numValidContrasts = sum(~isnan(earlyHitRate) | ~isnan(lateHitRate));
            barWidth = 0.35;
            x = 1:numValidContrasts;
            
            % Filter out NaN values
            validIdx = ~isnan(earlyHitRate) | ~isnan(lateHitRate);
            validContrasts = sortedContrasts(validIdx);
            validEarlyRate = earlyHitRate(validIdx);
            validLateRate = lateHitRate(validIdx);
            
            % Create bar chart
            earlyBar = bar(x - barWidth/2, validEarlyRate, barWidth, 'FaceColor', 'b');
            lateBar = bar(x + barWidth/2, validLateRate, barWidth, 'FaceColor', 'r');
            
            % Add contrast labels to x-axis
            xticks(x);
            xticklabels(arrayfun(@(c) sprintf('%d%%', c), validContrasts, 'UniformOutput', false));
            
            % Add data labels on top of bars
            for i = 1:length(validEarlyRate)
                if ~isnan(validEarlyRate(i))
                    text(i - barWidth/2, validEarlyRate(i) + 0.03, ...
                        sprintf('%.0f%%', validEarlyRate(i)*100), ...
                        'HorizontalAlignment', 'center', 'FontSize', 8);
                end
            end
            
            for i = 1:length(validLateRate)
                if ~isnan(validLateRate(i))
                    text(i + barWidth/2, validLateRate(i) + 0.03, ...
                        sprintf('%.0f%%', validLateRate(i)*100), ...
                        'HorizontalAlignment', 'center', 'FontSize', 8);
                end
            end
            
            % Format plot
            title('Hit Rates by Contrast: Early vs Late Trials', 'FontSize', 14);
            xlabel('Contrast', 'FontSize', 12);
            ylabel('Hit Rate', 'FontSize', 12);
            ylim([0 1.1]);
            grid on;
            legend([earlyBar, lateBar], {'Early Trials', 'Late Trials'}, 'Location', 'best');
            
            % Plot 2: Number of trials by contrast for early vs late
            subplot(2, 2, 2);
            hold on;
            
            % Filter out zero values
            validTrialsIdx = (earlyHits + earlyMisses > 0) | (lateHits + lateMisses > 0);
            trialContrasts = sortedContrasts(validTrialsIdx);
            earlyTotal = earlyHits(validTrialsIdx) + earlyMisses(validTrialsIdx);
            lateTotal = lateHits(validTrialsIdx) + lateMisses(validTrialsIdx);
            
            % Create bar chart
            x = 1:length(trialContrasts);
            earlyTrialsBar = bar(x - barWidth/2, earlyTotal, barWidth, 'FaceColor', 'b');
            lateTrialsBar = bar(x + barWidth/2, lateTotal, barWidth, 'FaceColor', 'r');
            
            % Add contrast labels to x-axis
            xticks(x);
            xticklabels(arrayfun(@(c) sprintf('%d%%', c), trialContrasts, 'UniformOutput', false));
            
            % Add data labels on top of bars
            for i = 1:length(earlyTotal)
                if earlyTotal(i) > 0
                    text(i - barWidth/2, earlyTotal(i) + 0.5, sprintf('%d', earlyTotal(i)), ...
                        'HorizontalAlignment', 'center', 'FontSize', 8);
                end
            end
            
            for i = 1:length(lateTotal)
                if lateTotal(i) > 0
                    text(i + barWidth/2, lateTotal(i) + 0.5, sprintf('%d', lateTotal(i)), ...
                        'HorizontalAlignment', 'center', 'FontSize', 8);
                end
            end
            
            % Format plot
            title('Trial Counts by Contrast: Early vs Late', 'FontSize', 14);
            xlabel('Contrast', 'FontSize', 12);
            ylabel('Number of Trials', 'FontSize', 12);
            grid on;
            legend([earlyTrialsBar, lateTrialsBar], {'Early Trials', 'Late Trials'}, 'Location', 'best');
            
            % Plot 3 & 4: Dopamine traces for early and late hit trials
            % Get contrast-specific neural fields
            fields = fieldnames(allData(fileIdx).tdtHitCont);
            hitFields = fields(contains(fields, 'Hits_contrast'));
            
            % Extract contrast numbers from fields
            contrastNums = cellfun(@(x) str2double(regexp(x, '\d+', 'match')), hitFields);
            [sortedDAContrasts, sortDAIdx] = sort(contrastNums);
            sortedDAFields = hitFields(sortDAIdx);
            
            % Create subplot for early trials
            subplot(2, 2, 3);
            hold on;
            
            % Plot early traces
            plotDATraces(allData, fileIdx, sortedDAFields, sortedDAContrasts, 'early', medianTime, baseColors);
            title('Early Hit Trials: Dopamine Traces by Contrast', 'FontSize', 14);
            
            % Create subplot for late trials
            subplot(2, 2, 4);
            hold on;
            
            % Plot late traces
            plotDATraces(allData, fileIdx, sortedDAFields, sortedDAContrasts, 'late', medianTime, baseColors);
            title('Late Hit Trials: Dopamine Traces by Contrast', 'FontSize', 14);
            
            % Save the figure
            savePath = fullfile(pwd, 'figures');
            if ~exist(savePath, 'dir')
                mkdir(savePath);
            end
            
            figFilename = sprintf('EarlyLate_%d_%s.png', fileIdx, dateStr);
            fullFilePath = fullfile(savePath, figFilename);
            print(gcf, fullFilePath, '-dpng', '-r300');
            fprintf('Figure saved to: %s\n', fullFilePath);
            
        catch ME
            warning('Error analyzing early vs late trials for dataset %d: %s', fileIdx, ME.message);
        end
    end
    
    % Restore original figure visibility
    set(0, 'DefaultFigureVisible', originalVisibility);
end

function plotDATraces(allData, fileIdx, sortedFields, sortedContrasts, timePeriod, medianTime, colors)
    % Function to plot dopamine traces by contrast for early or late trials
    % Inputs:
    %   allData - main data structure
    %   fileIdx - index of current file
    %   sortedFields - sorted field names for contrasts
    %   sortedContrasts - sorted contrast values
    %   timePeriod - 'early' or 'late'
    %   medianTime - time cutoff between early and late
    %   colors - color palette to use
    
    legendHandles = [];
    legendLabels = {};
    
    % Find the field with the largest number of trials to normalize
    maxPeak = -inf;
    for i = 1:length(sortedFields)
        currentField = sortedFields{i};
        if ~isfield(allData(fileIdx).tdtHitCont, currentField)
            continue;
        end
        
        currentData = allData(fileIdx).tdtHitCont.(currentField);
        if ~isfield(currentData, 'zall') || ~isfield(currentData, 'ts2')
            continue;
        end
        
        % Find peak in window
        ts2 = currentData.ts2;
        window = ts2 >= 0.45 & ts2 <= 0.6;
        meanData = mean(currentData.zall, 1);
        windowData = meanData(window);
        [peak, ~] = max(windowData);
        
        if peak > maxPeak
            maxPeak = peak;
        end
    end
    
    % Plot each contrast
    for i = 1:length(sortedFields)
        currentField = sortedFields{i};
        contrastNum = sortedContrasts(i);
        
        % Skip if field doesn't exist
        if ~isfield(allData(fileIdx).tdtHitCont, currentField)
            continue;
        end
        
        currentData = allData(fileIdx).tdtHitCont.(currentField);
        if ~isfield(currentData, 'zall') || ~isfield(currentData, 'ts2')
            continue;
        end
        
        % Get trial timestamps for this contrast
        hitField = ['hitTrials_contrast' num2str(contrastNum)];
        if ~isfield(allData(fileIdx).behavior, hitField)
            continue;
        end
        
        hitTimestamps = allData(fileIdx).behavior.(hitField);
        
        % Select early or late trials
        if strcmp(timePeriod, 'early')
            trialMask = hitTimestamps < medianTime;
        else
            trialMask = hitTimestamps >= medianTime;
        end
        
        % Skip if no trials in this period
        if sum(trialMask) < 1
            continue;
        end
        
        % Get corresponding indices in the zall data
        % This is tricky since we need to match timestamps to trials
        % For simplicity, we'll use all trials if we can't match exactly
        
        % Get time vector and z-scores
        ts2 = currentData.ts2;
        zall = currentData.zall;
        
        % If we can identify the specific trials, use those
        if size(zall, 1) == length(hitTimestamps)
            zall_filtered = zall(trialMask, :);
        else
            % Otherwise use all trials (not ideal but allows code to run)
            zall_filtered = zall;
            warning('Cannot match trial timestamps for %s - using all trials', currentField);
        end
        
        % Calculate mean and error
        meanData = mean(zall_filtered, 1) / maxPeak; % Normalize
        if size(zall_filtered, 1) > 1
            errorData = std(zall_filtered, [], 1) / sqrt(size(zall_filtered, 1)) / maxPeak;
        else
            errorData = zeros(size(meanData));
        end
        
        % Use modulo to cycle through colors for datasets with many contrasts
        colorIdx = mod(i-1, size(colors, 1)) + 1;
        
        % Plot mean line
        h = plot(ts2, meanData, 'Color', colors(colorIdx,:), 'LineWidth', 2);
        
        % Add shaded error area
        fill([ts2, fliplr(ts2)], [meanData+errorData, fliplr(meanData-errorData)], ...
            colors(colorIdx,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % Add to legend
        legendHandles = [legendHandles, h];
        legendLabels{end+1} = sprintf('%d%% (%d trials)', contrastNum, size(zall_filtered, 1));
    end
    
    % Add reference lines
    line([0 0], [-1 2], 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '--');
    line([0 3], [0 0], 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '--');
    
    % Format plot
    xlim([0 3]);
    ylim([-0.5 1.5]);
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Normalized Z-score', 'FontSize', 12);
    grid on;
    
    % Add legend if we have any traces
    if ~isempty(legendHandles)
        legend(legendHandles, legendLabels, 'Location', 'northeast', 'Box', 'off');
    end
end