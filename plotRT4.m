function plotRT4(allData, sessionIdx)
 % PLOTRTVDA Create a balanced 3-panel figure showing CS times and reaction time relationships
%
% Inputs:
% allData - Master data structure
% sessionIdx - Session index to analyze (default: 1)
% Default to first session if not specified
if nargin < 2
 sessionIdx = 1;
end
% Create figure with 3 subplots arranged in a balanced way
 figure('Position', [50 50 1000 600]);
% Try to get reaction time data
 reactTimes = allData(sessionIdx).behavior.reactTimeMs;
% Try to get time and z-score data
if isfield(allData(sessionIdx).tdtAnalysis, 'Hits')
 ts2 = allData(sessionIdx).tdtAnalysis.Hits.ts2;
 zall = allData(sessionIdx).tdtAnalysis.Hits.zall;
 maxValues = allData(sessionIdx).tdtAnalysis.Hits.maxValues;
 maxIndices = allData(sessionIdx).tdtAnalysis.Hits.maxIndices;
else
 error('Hit data not found in allData(%d).tdtAnalysis.Hits', sessionIdx);
end
% Get the number of trials
 numTrials = size(zall, 1);
% Initialize arrays for time of maxes
 timeOfMaxes = zeros(numTrials, 1);
% Calculate time of maximum for each trial
for i = 1:numTrials
% Time of maximum
if maxIndices(i) <= length(ts2)
 timeOfMaxes(i) = ts2(maxIndices(i));
end
end
% PLOT 1: CS Peak DA vs reaction time
 subplot(1, 3, 1);
 scatter(reactTimes, maxValues, 60, 'b', 'filled', 'MarkerFaceAlpha', 0.7);
 title('CS Peak DA vs Reaction Time', 'FontSize', 12);
 xlabel('Reaction Time (ms)', 'FontSize', 10);
 ylabel('Peak DA (Z-score)', 'FontSize', 10);
% PLOT 2: Reaction time vs Time of CS maximum
 subplot(1, 3, 2);
 scatter(reactTimes, timeOfMaxes, 60, 'm', 'filled', 'MarkerFaceAlpha', 0.7);
 title('Reaction Time vs Time of CS Maximum', 'FontSize', 12);
 xlabel('Reaction Time (ms)', 'FontSize', 10);
 ylabel('Time of Maximum (s)', 'FontSize', 10);
 ylim([0 2]);
% PLOT 3: Distribution of reaction times
 subplot(1, 3, 3);
 histogram(reactTimes, 20, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'none');
 title('Distribution of Reaction Times', 'FontSize', 12);
 xlabel('Reaction Time (ms)', 'FontSize', 10);
 ylabel('Count', 'FontSize', 10);
% Add overall title
 sgtitle(sprintf('Session %d: DA Response and Reaction Time Analysis', sessionIdx), 'FontSize', 14);
end