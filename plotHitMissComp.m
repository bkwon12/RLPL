function plotHitMissComp(allData)
    % PLOTHITMISSCOMPARISON Plot comparison of hit and miss trials for each dataset
    % Creates a figure with heatmap and averaged z-score plots for each dataset
    % Input:
    %   allData - Structure array containing processed photometry data
    
    for fileIdx = 1:length(allData)
        % Create figure with specific size
        fig2 = figure('Name', sprintf('Dataset %d Hit vs Miss Trials', fileIdx));
        fig2.Position(3:4) = [1200 630];
        
        % Create overall title with session number
        sgtitle(sprintf('Session %d: Hit vs Miss Comparison', fileIdx), 'FontSize', 16, 'FontWeight', 'bold');
        
        % Get hit and miss trials data from tdtAnalysis
        hitZall = allData(fileIdx).tdtAnalysis.Hits.zall;
        missZall = allData(fileIdx).tdtAnalysis.Misses.zall;
        
        % Calculate trial numbers
        numHitsTrials = allData(fileIdx).tdtAnalysis.Hits.trialNum;
        numMissTrials = allData(fileIdx).tdtAnalysis.Misses.trialNum;
        totalTrials = numHitsTrials + numMissTrials;
        
        % Get time vector
        ts2 = allData(fileIdx).tdtAnalysis.Hits.ts2;
        
        % Combine data for heatmap
        combinedZall = [hitZall; missZall];
        
        % Define subplot positions
        pos1 = [0.1 0.15 0.35 0.75];
        pos2 = [0.55 0.15 0.35 0.75];
        
        % Plot combined heatmap
        subplot('Position', pos1)
        imagesc(ts2, 1:totalTrials, combinedZall);
        hold on
        
        % Add separation line
        line([min(ts2) max(ts2)], [numHitsTrials numHitsTrials], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 2)
        
        % Set up y-ticks
        yticks_hits = [0:40:numHitsTrials];
        ylabels_hits = cellstr(num2str(yticks_hits'));
        yticks_misses = numHitsTrials + [0:40:numMissTrials];
        ylabels_misses = cellstr(num2str([0:40:numMissTrials]'));
        
        set(gca, 'YTick', [yticks_hits yticks_misses])
        set(gca, 'YTickLabel', [ylabels_hits; ylabels_misses])
        
        % Configure colormap
        colormap('jet')
        cb = colorbar('east');
        cb.Position = [0.465 0.15 0.02 0.75];
        cb.TickDirection = 'out';
        cb.AxisLocation = 'out';
        peakValue = max([max(hitZall(:)), max(missZall(:))]);
        caxis([1.3 peakValue]);
        
        % Set x-axis limits to show -3 to 3 seconds
        xlim([-3 3]);
        
        % Add labels
        title(sprintf('Z-Score Heat Plot: Hits (%d) and Misses (%d)', numHitsTrials, numMissTrials));
        ylabel('Trials', 'FontSize', 12);
        xlabel('Time, s', 'FontSize', 12);
        
        % Plot averaged data
        subplot('Position', pos2)
        set(gca, 'TickDir', 'out')
        hold on;
        
        % Calculate smoothed averages - using a moving average filter
        windowSize = 15; % Adjust for more or less smoothing
        
        % Plot hits average (smoothed)
        hitMean = mean(hitZall);
        hitMeanSmooth = movmean(hitMean, windowSize);
        hitError = allData(fileIdx).tdtAnalysis.Hits.zerror;
        hitErrorSmooth = movmean(hitError, windowSize);
        
        XX = [ts2, fliplr(ts2)];
        YY = [hitMeanSmooth-hitErrorSmooth, fliplr(hitMeanSmooth+hitErrorSmooth)];
        
        % Plot fill first
        h1 = fill(XX, YY, 'g');
        set(h1, 'facealpha', .25, 'edgecolor', 'none', 'HandleVisibility', 'off')  % Hide from legend
        
        % Then plot line
        hPlot1 = plot(ts2, hitMeanSmooth, 'color', [0.3500, 0.5325, 0.0980], 'LineWidth', 3);
        
        % Plot miss average (smoothed)
        missMean = mean(missZall);
        missMeanSmooth = movmean(missMean, windowSize);
        missError = allData(fileIdx).tdtAnalysis.Misses.zerror;
        missErrorSmooth = movmean(missError, windowSize);
        
        XX = [ts2, fliplr(ts2)];
        YY = [missMeanSmooth-missErrorSmooth, fliplr(missMeanSmooth+missErrorSmooth)];
        
        % Plot fill first
        h2 = fill(XX, YY, 'r');
        set(h2, 'facealpha', .25, 'edgecolor', 'none', 'HandleVisibility', 'off')  % Hide from legend
        
        % Then plot line
        hPlot2 = plot(ts2, missMeanSmooth, 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 3);
        
        % Add reference lines
        line([min(ts2) max(ts2)], [0 0], 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1);
        ylims = get(gca, 'YLim');
        line([0 0], ylims, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1);
        
        % Set x-axis limits to show -3 to 3 seconds
        xlim([-3 3]);
        
        % Add legend for just the lines
        legend([hPlot1, hPlot2], 'Hits', 'Misses', 'Location', 'northeast', 'FontSize', 12)
        
        % Keep y-axis automatic but ensure x-axis is fixed
        xlabel('Time, s', 'FontSize', 12)
        ylabel('Z-score', 'FontSize', 12)
        title('Averaged Z-Score: Hits vs Misses');
    end
end