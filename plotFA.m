function plotFA(allData)
    % PLOTFALSEALARMACTIVITY Plot heatmap and average z-scores for false alarm trials
    % Creates a figure with heatmap and averaged z-score plots for each dataset
    % Input:
    %   allData - Structure array containing processed photometry data
    
    for fileIdx = 1:length(allData)
        % Skip if no false alarm data exists
        if ~isfield(allData(fileIdx), 'tdtAnalysis') || ~isfield(allData(fileIdx).tdtAnalysis, 'FA') || ...
           isempty(allData(fileIdx).tdtAnalysis.FA.zall)
            fprintf('No false alarm data found for session %d. Skipping...\n', fileIdx);
            continue;
        end
        
        % Create figure with specific size
        fig = figure('Name', sprintf('Dataset %d False Alarm Trials', fileIdx));
        fig.Position(3:4) = [1200 630];
        
        % Create overall title with session number
        sgtitle(sprintf('Session %d: False Alarm Activity', fileIdx), 'FontSize', 16, 'FontWeight', 'bold');
        
        % Get FA trials data from tdtAnalysis
        faZall = allData(fileIdx).tdtAnalysis.FA.zall;
        
        % Calculate trial numbers
        numFATrials = allData(fileIdx).tdtAnalysis.FA.trialNum;
        
        % Get time vector
        ts2 = allData(fileIdx).tdtAnalysis.FA.ts2;
        
        % Define subplot positions
        pos1 = [0.1 0.15 0.35 0.75];
        pos2 = [0.55 0.15 0.35 0.75];
        
        % Plot heatmap
        subplot('Position', pos1)
        imagesc(ts2, 1:numFATrials, faZall);
        hold on
        
        % Set up y-ticks - match pattern from plotHitMissComp
        yticks_fa = [0:40:numFATrials]; % Changed to match 40-unit spacing of original
        if isempty(yticks_fa)
            yticks_fa = [0, numFATrials];
        end
        ylabels_fa = cellstr(num2str(yticks_fa'));
        
        set(gca, 'YTick', yticks_fa)
        set(gca, 'YTickLabel', ylabels_fa)
        
        % Configure colormap - exactly match original
        colormap('jet')
        cb = colorbar('east');
        cb.Position = [0.465 0.15 0.02 0.75];
        cb.TickDirection = 'out';
        cb.AxisLocation = 'out';
        peakValue = max(faZall(:));
        caxis([1.3 peakValue]); % Match exactly the 1.3 lower bound used in original
        
        % Set x-axis limits to show -3 to 3 seconds
        xlim([-3 3]);
        
        % Add vertical line at t=0 (event onset)
        line([0 0], [0 numFATrials], 'Color', 'w', 'LineStyle', '--', 'LineWidth', 2);
        
        % Add labels - match original format
        title(sprintf('Z-Score Heat Plot: False Alarms (%d)', numFATrials));
        ylabel('Trials', 'FontSize', 12);
        xlabel('Time, s', 'FontSize', 12);
        
        % Plot averaged data
        subplot('Position', pos2)
        set(gca, 'TickDir', 'out')
        hold on;
        
        % Calculate smoothed averages - using a moving average filter with increased window size
        windowSize = 45; % Increased from 15 to 45 for smoother appearance
        
        % Plot FA average (smoothed) - follow exactly the same pattern as original
        faMean = mean(faZall);
        faMeanSmooth = movmean(faMean, windowSize);
        faError = allData(fileIdx).tdtAnalysis.FA.zerror;
        faErrorSmooth = movmean(faError, windowSize);
        
        XX = [ts2, fliplr(ts2)];
        YY = [faMeanSmooth-faErrorSmooth, fliplr(faMeanSmooth+faErrorSmooth)];
        
        % Plot fill first - use blue instead of green/red
        h1 = fill(XX, YY, 'b');
        set(h1, 'facealpha', .25, 'edgecolor', 'none', 'HandleVisibility', 'off')  % Hide from legend
        
        % Then plot line
        hPlot1 = plot(ts2, faMeanSmooth, 'color', [0, 0.4470, 0.7410], 'LineWidth', 3);
        
        % Add reference lines
        line([min(ts2) max(ts2)], [0 0], 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1);
        ylims = get(gca, 'YLim');
        line([0 0], ylims, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1);
        
        % Set x-axis limits to show -3 to 3 seconds
        xlim([-3 3]);
        
        % Add legend exactly as in original
        legend(hPlot1, 'False Alarms', 'Location', 'northeast', 'FontSize', 12)
        
        % Keep y-axis automatic but ensure x-axis is fixed
        xlabel('Time, s', 'FontSize', 12)
        ylabel('Z-score', 'FontSize', 12)
        title('Averaged Z-Score: False Alarm Trials');
    end
end