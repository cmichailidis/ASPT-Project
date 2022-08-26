% Clear all workspace variables,
% Close any open windows and
% clear the command line.
clear all; close all; clc;

% ------------------------ Script Parameters ------------------------

% Hyperparameters for 
% estimating the bicoherence
K = 32;                         % Number of segments
fs = 256;                       % Sampling frequency
fc = 32;                        % upper bound on frequency axis

% Select patients and an EEG
% channels from the dataset
channel = 1;                    % EEG channel
start = 1;                      % first patient
stop = 50;                      % last patient

% Plot settings
nbins = 100;                    % Number of histogram bins
norm = "pdf";                   % Normalization type for histograms:
                                % cdf => cumulative distribution 
                                % pdf => probability density function

% ---------------- Do not change anything below ---------------------

% Initialize an empty table to store bicoherence features
sz = [0 4];
types = ["double" "double" "double" "string"];
names = ["ent1" "ent2" "ent3" "Annotations"];
Y = table('Size',sz,'VariableTypes',types,'VariableNames',names);

% Extract bicoherence features from every patient
for i = start:stop
    txt = sprintf("SN%03d.edf",i);
    if ~isfile(txt) continue; end

    fprintf("Loading EDF files for patient %d ... ",i);
    Z = loadEDF(i);
    fprintf("OK\n");

    fprintf("Estimating bicoherence matrix ... ");
    [X,~] = bicEEG(Z,K,fs,fc,channel);
    fprintf("OK\n");

    fprintf("Extracting bicoherence features ... ");
    Y = [Y; bicoherFeatures(X)];
    fprintf("OK\n");

    fprintf("\n");
end

% ---------- Plot histograms of the bicoherence features ------------

% Boolean masks to distinguish between the five sleep stages
W  = Y.Annotations == "Sleep stage W";
R  = Y.Annotations == "Sleep stage R";
N1 = Y.Annotations == "Sleep stage N1";
N2 = Y.Annotations == "Sleep stage N2";
N3 = Y.Annotations == "Sleep stage N3";

% histograms of bicoherence entropy
z1 = Y{W, "ent1"};
z2 = Y{R, "ent1"};
z3 = Y{N1,"ent1"};
z4 = Y{N2,"ent1"};
z5 = Y{N3,"ent1"};

figure(1); hold on; grid on;
histogram(z1,'DisplayStyle','stairs','Normalization',norm);
histogram(z2,'DisplayStyle','stairs','Normalization',norm);
histogram(z3,'DisplayStyle','stairs','Normalization',norm);
histogram(z4,'DisplayStyle','stairs','Normalization',norm);
histogram(z5,'DisplayStyle','stairs','Normalization',norm);
xlabel("bicoherence entropy");
ylabel("probability");
legend("W","R","N1","N2","N3");

fprintf("Statistics for bicoherence entropy:\n");
fprintf("-------------------------------------------\n");
fprintf("stage W  => mean: %.4f std: %.4f\n", mean(z1), std(z1));
fprintf("stage R  => mean: %.4f std: %.4f\n", mean(z2), std(z2));
fprintf("stage N1 => mean: %.4f std: %.4f\n", mean(z3), std(z3));
fprintf("stage N2 => mean: %.4f std: %.4f\n", mean(z4), std(z4));
fprintf("stage N3 => mean: %.4f std: %.4f\n", mean(z5), std(z5));
fprintf("\n");

% histogram of bicoherence squared-entropy
z1 = Y{W, "ent2"};  
z2 = Y{R, "ent2"}; 
z3 = Y{N1,"ent2"};  
z4 = Y{N2,"ent2"}; 
z5 = Y{N3,"ent2"};  

figure(2); hold on; grid on;
histogram(z1,'DisplayStyle','stairs','Normalization',norm);
histogram(z2,'DisplayStyle','stairs','Normalization',norm);
histogram(z3,'DisplayStyle','stairs','Normalization',norm);
histogram(z4,'DisplayStyle','stairs','Normalization',norm);
histogram(z5,'DisplayStyle','stairs','Normalization',norm);
xlabel("bicoherence squared-entropy");
ylabel("probability");
legend("W","R","N1","N2","N3");

fprintf("Statistics for bicoherence squared-entropy:\n");
fprintf("-------------------------------------------\n");
fprintf("stage W  => mean: %.4f std: %.4f\n", mean(z1), std(z1));
fprintf("stage R  => mean: %.4f std: %.4f\n", mean(z2), std(z2));
fprintf("stage N1 => mean: %.4f std: %.4f\n", mean(z3), std(z3));
fprintf("stage N2 => mean: %.4f std: %.4f\n", mean(z4), std(z4));
fprintf("stage N3 => mean: %.4f std: %.4f\n", mean(z5), std(z5));
fprintf("\n");

% histograms of bicoherence cubic-entropy
z1 = Y{W, "ent3"};  
z2 = Y{R, "ent3"};  
z3 = Y{N1,"ent3"};  
z4 = Y{N2,"ent3"}; 
z5 = Y{N3,"ent3"}; 

figure(3); hold on; grid on;
histogram(z1,'DisplayStyle','stairs','Normalization',norm);
histogram(z2,'DisplayStyle','stairs','Normalization',norm);
histogram(z3,'DisplayStyle','stairs','Normalization',norm);
histogram(z4,'DisplayStyle','stairs','Normalization',norm);
histogram(z5,'DisplayStyle','stairs','Normalization',norm);
xlabel("bicoherence cubic-entropy");
ylabel("probability");
legend("W","R","N1","N2","N3");

fprintf("Statistics for bicoherence cubic-entropy:\n");
fprintf("-------------------------------------------\n");
fprintf("stage W  => mean: %.4f std: %.4f\n", mean(z1), std(z1));
fprintf("stage R  => mean: %.4f std: %.4f\n", mean(z2), std(z2));
fprintf("stage N1 => mean: %.4f std: %.4f\n", mean(z3), std(z3));
fprintf("stage N2 => mean: %.4f std: %.4f\n", mean(z4), std(z4));
fprintf("stage N3 => mean: %.4f std: %.4f\n", mean(z5), std(z5));
fprintf("\n");