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
wavelet = "db5";                    

% logical array for reconstruction 
% -> frequency boundaries are calculated
%    assuming a sampling rate of 256Hz
levelForReconstruction = [
    false, ...     % 64 - 128
    false, ...     % 32 - 64
    true,  ...     % 16 - 32
    true,  ...     % 8 - 16
    true,  ...     % 4 - 8
    true   ...     % 0 - 4
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

% =========================================================
% 5) Plots of Delta, Theta, Alpha and Beta waves
% =========================================================

figure(idx); tiledlayout(4,1); idx = idx + 1;

% Delta waves
ax(1) = nexttile;
plot(time, mra(6,:));
xlabel('time in seconds');
ylabel('Amplitude');
title('Delta waves');

% Theta waves
ax(2) = nexttile;
plot(time, mra(5,:));
xlabel('time in seconds');
ylabel('Amplitude');
title('Theta waves');

% Alpha waves
ax(3) = nexttile;
plot(time, mra(4,:));
xlabel('time in seconds');
ylabel('Amplitude');
title('Alpha waves');

% Beta waves
ax(4) = nexttile; 
plot(time, mra(3,:));
xlabel('time in seconds');
ylabel('Amplitude');
title('Beta waves');

linkaxes(ax, 'x');