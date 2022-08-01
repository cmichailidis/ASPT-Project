% ======================================================
% Demo Script (3)
% ------------------------------------------------------
%
% Author: Christodoulos Michaelides, July 2022
% ------------------------------------------------------
%
% Objectives:
% ------------------------------------------------------
% 1) Use Multi-Resolution-Analysis on the entire 
% recording of an EEG/EOG/ECG channel
%
% 2) Choose the most appropriate frequency scales
% to reconstruct an approximation of the original
% recording
% 
% 3) Estimate 2nd, 3rd and 4th order moments
% for every frequency scale independently. 
% Use a time window of 30 seconds, when 
% estimating variance, skewness and kurtosis in 
% order to obtain localised estimates of the above
% quantities.
% 
% 4) Plot the standard deviation, skewness and 
% kurtosis of every scale with respect to time
% and compare those quantities with the hypnogram
% of the patient.
%
% 5) For every 30-second interval plot the standard
% deviation, skewness and kurtosis of the current
% % frequency scale as a point in 3D space. 
% Connect those points to form a curved line.
% This line should form a closed trajectory in 3D
% % space since the beginning and the ending of every
% recording corresponds to the patient being awake.
%
% 6) Repeat the previous step, only this time use a
% different color for every 3D point depending on 
% the sleep stage. See if those points form any 
% distinct color clusters in 3D space.
% ======================================================

% reset your workspace and clear terminal
clear all; close all; clc;

% ======================================================
% 1) Parameters of MRA Decomposition and Reconstruction
% (Choose any value that you want to experiment with)
% ======================================================

% name of input file
input_file = "SN001.edf";            

% name of annotations file
annot_file = "SN001_sleepscoring.edf";

% index of selected channel
% index: signal label
% 1:     EEG F4-M1
% 2:     EEG C4-M1
% 3:     EEG O2-M1
% 4:     EEG C3-M2
% 5:     EMG chin
% 6:     EOG E1-M2
% 7:     EOG E2-M2
% 8:     ECG
channel = 1;

% wavelet for MRA
wavelet = "db2";                    

% logical array for reconstruction 
% -> frequency boundaries are calculated
%    assuming a sampling rate of 256Hz
levelForReconstruction = [
    false,  ...     % scale 1 (64-128 Hz)
    false,  ...     % scale 2 (32-64 Hz)  
    true,   ...     % scale 3 (16-32 Hz)
    true,   ...     % scale 4 (8-16 Hz)
    true,   ...     % scale 5 (4-8 Hz)
    true,   ...     % scale 6 (2-4 Hz)
    true    ...     % scale 7 (0-2 Hz)
];

% ------------------------------------------------------
% Do not change anything below that point, 
% unless you know exactly what you are doing.
% ------------------------------------------------------

% window lenth for estimating higher order statistics
w = duration("00:00:30");

% number of frequency scales
num_of_scales = length(levelForReconstruction);

% number of levels on MRA binary tree
levels = num_of_scales - 1;

% validity checks on selected frequency scales
if levels < 1
    fprintf('Error ...\n');
    fprintf('MRA requires at least one decomposition level\n');
    fprintf('Abort ...\n');
    return;
end

if all(levelForReconstruction == false)
    fprintf('Error:\n');
    fprintf('Select at least one frequency scale\n');
    fprintf('Abort ...\n');
    return;
end

% ======================================================
% 2) Read data from the EDF file
% ======================================================

% Progress Status
fprintf("Loading input file ...  "); tic;

% Read the entire EDF file
X = edfread(input_file);

% Read file metadata
info = edfinfo(input_file);

% choose the appropriate channel
sig = X{:,channel}; sig = cell2mat(sig);     

% Read the annotations from the 
% sleep scoring EDF file
[~,labels] = edfread(annot_file);

% N:  number of data records per recording
% d:  duration of every data record in seconds
% n:  samples per data record
% fs: sampling frequency in Hertz
N = info.NumDataRecords;
d = seconds(info.DataRecordDuration);
n = info.NumSamples(channel);
fs = n / d;

% Extract the sequence of the sleep stages
% from the Annotations timetable and remove
% unnecessary events regarding changes in
% the light level
% array of valid sleep stages
% (you should probably leave
% this as it is)
stages = cellstr(       ...
    ["Sleep stage W",   ...
     "Sleep stage N1",  ...
     "Sleep stage N2",  ...
     "Sleep stage N3",  ...
     "Sleep stage R"]   ...
);

labels = removevars(labels, "Duration");
rows = ~ismember(categorical(labels.Annotations), categorical(stages)); 
labels(rows,:) = [];
labels.Annotations = categorical(labels.Annotations);
labels.Annotations = reordercats(labels.Annotations, stages);
labels.Annotations = renamecats( ...
    labels.Annotations,          ...
    stages,                      ...
    ["W" "N1" "N2" "N3" "R"]     ...  
);

stages = cellstr(["W" "N1" "N2" "N3" "R"]);

% delete unused variables
clear X;

% Progress Status
fprintf("Done\n\n"); toc; fprintf("\n");

% ======================================================
% 3) Perform MRA decomposition and reconstruction
% ======================================================

% Progress Status
fprintf("Performing MRA ... "); tic;

% Perform the decomposition using modwt
wt = modwt(sig,wavelet,levels);

% Construct MRA matrix using modwtmra
mra = modwtmra(wt,wavelet);

% Sum down the rows of the selected multiresolution signals
sig1 = sum(mra(levelForReconstruction,:),1);

% Delete unused variables
clear wt;  

% Progress Status
fprintf("Done\n\n"); toc; fprintf("\n"); 

% ======================================================
% 4) Plot of Original vs Reconstructed Waveform
% ======================================================            

% incremental index for the number of plots
idx = 1;

% Reconstructed vs Original Signal
figure(idx); idx = idx + 1;

% construct a time axis for
% the EEG/EOG/ECG channel
time = linspace(0, N*d, N*d*fs); 

% Plot settings
plt = plot(time,sig,time,sig1);
plt(1).LineWidth = 0.5; 
plt(2).LineWidth = 2.0;

% Plot axes and title
legend('Original Signal', 'Reconstructed Signal');
xlabel("time in seconds");
ylabel("Amplitude in microVolts");
title("Original vs Reconstruction");

% ======================================================
% 5) Estimate variance/skewness/kurtosis
% in a sliding window.
% ======================================================

% length of sliding window in samples
w = seconds(w);
l = w * fs;

% number of segments created by sliding window
[K, ~] = size(labels);

% time axis for the following plots
time = (0:1:(K-1)) * w;

% frequency boundaries for every analysis scale
freq = (fs/2) * 2.^-[0:levels];
freq = [freq 0];

% Plots of selected frequency scales
% and sliding window statistics
for i = 1:1:num_of_scales
    % ignore discarded frequency scales
    if levelForReconstruction(i) == false
        continue;
    end

    % Progress Status
    fprintf("Estimating statistics for scale %d ... ", i);
    
    % f1: lower bound of frequency scale in Hertz
    % f2: upper bound of frequency scale in Hertz
    f1 = freq(i+1);
    f2 = freq(i+0);

    % estimate higher order moments
    x = mra(i,1:K*w*fs);
    x = reshape(x, K, l);
    m   = sum(x,2) / l;            % sliding average 
    var = sum((x-m).^2, 2) / l;    % sliding variance
    std = sqrt(var);               % sliding standard deviation
    skw = sum((x-m).^3, 2) / l;    % sliding 3rd moment
    krt = sum((x-m).^4, 2) / l;    % sliding 4th moment
    skw = skw ./ (std.^3);         % sliding skewness
    krt = krt ./ (std.^4);         % sliding kurtosis

    % 3D space plot of high order statistics
    figure(idx); idx = idx + 1;
    plot3(std, skw, krt); grid on;
    xlabel('Standard Deviation');
    ylabel('Skewness');
    zlabel('Kurtosis');
    title(sprintf('Scatter Plot: %.2fHz - %.2fHz', f1, f2));

    % Plots of higher order statistics
    % with respect to time
    figure(idx); idx = idx + 1; 
    t = tiledlayout(4,1);

    % subplot of hypnogram
    x0 = nexttile;
    plot(x0, time, labels.Annotations);
    xlabel('time in seconds');
    ylabel('Sleep stage');
    title('Hypnogram');

    % subplot of sliding variance
    x1 = nexttile;
    plot(x1, time, std);
    xlabel('time in seconds');
    ylabel('Std. Deviation');
    title(sprintf("Scale %d: %.2fHz-%.2fHz",i,f1,f2));

    % subplot of sliding skewness
    x2 = nexttile;             
    plot(x2, time, skw);
    xlabel('time in seconds');
    ylabel('Skewness');

    % subplot of sliding kurtosis
    x3 = nexttile;                     
    plot(x3, time, krt); 
    xlabel('time in seconds');
    ylabel('Kurtosis');

    % Link time axes
    linkaxes([x0 x1 x2 x3], 'x');

    % scatter plot of higher order statistics
    figure(idx); idx = idx + 1; hold on; grid on;
    xlabel('Standard Deviation');
    ylabel('Skewness');
    zlabel('Kurtosis');
    title(sprintf('Scatterplot, %.2fHz-%.2fHz',f1,f2));

    colors = ['r', 'g', 'g', 'g', 'b'];

    for j = 1:1:length(stages)
        scatter3(                                 ...
            std(labels.Annotations == stages(j)), ...
            skw(labels.Annotations == stages(j)), ...
            krt(labels.Annotations == stages(j)), ...
            10,                                   ...
            colors(j),                            ...
            'filled'                              ...
        );
    end

    legend(stages);

    % Progress Status
    fprintf("Done\n\n");
end