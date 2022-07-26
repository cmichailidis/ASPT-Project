% ===================================================================
% Authors:    Chrysa Doulou
%             Christodoulos Michaelides
%             Demetrios Orphanos
%             Stergios Gregoriou
%
% Date:       October 2nd, 2022
% -------------------------------------------------------------------
%
% Script Description:
% This script extracts a wide variety of useful features from the
% polysomnographic recordings of the dataset. Those features include:
%   1) Bicoherence Features
%   2) Cepstrum Features
%   3) DWT features
%		4) features from EOG and EMG recordings
%
% Those features are stored in .mat files and can later be used to 
% to train classifiers for automatic sleep stage scoring.
% -------------------------------------------------------------------

% ===================================================================
% Clear all previous workspace variables
% ===================================================================

clear all;      % Delete workspace variables 
close all;      % Close all open windows
clc;            % Clear the terminal

% ===================================================================
% Script Parameters
% ===================================================================

first = 70;         % First patient selected from the dataset
last  = 154;        % Last patient selected from the dataset

fs = 256;           % Sampling frequency of PSG recordings (in Hertz)
dt = 30;            % Epoch duration of PSG recordings (in seconds)

K  = 24;            % Number of partitions for bicoherence matrices
fc = 32;            % Maximum frequency for bicoherence matrices

% Save-folder for feature files. (-mat files)
path = sprintf("C:\\Users\\USER\\Desktop\\features2");

% ------------- Do not change anything below that point -------------

% Create a separate folder to save the extracted features
if ~isfolder(path)
	mkdir(path);
end

% ===================================================================
% Feature Extraction
% ===================================================================

for n = first:1:last
    tic;

    % Make sure that the EDF/mat file exists
    edfFile = sprintf("SN%03d.edf",n);
    matFile = sprintf("%03d.mat",n);

    if (~isfile(edfFile)) && (~isfile(matFile))
        continue;
    end

    % Progress status
    fprintf("Patient %d:\n",n);

    % Load PSG recordings
    fprintf("Loading PSG recordings ... ");
    Z = loadEDF(n);
    fprintf("Done\n");

    % Preprocessing
    fprintf("Prefiltering ... ");
    Z = prefilter(Z,fs);
    fprintf("Done\n");

    % X: (2D array) Array of PSG features
    % y: (1D array) Array of Sleep stage Annotations
    X = [];
    y = table2array(Z(:,end));

    % ---------------- DWT Features ----------------
    
    fprintf("Performing MRA decomposition ... ");
    coeff1 = mraEEG(Z,"EEGF4_M1");
    coeff2 = mraEEG(Z,"EEGC4_M1");
    coeff3 = mraEEG(Z,"EEGO2_M1");
    coeff4 = mraEEG(Z,"EEGC3_M2");
    fprintf("Done\n");

    fprintf("Extracting features from DWT coefficients ... ");
    [D1, T1, A1, B1] = statEEG(coeff1);
    [D2, T2, A2, B2] = statEEG(coeff2);
    [D3, T3, A3, B3] = statEEG(coeff3);
    [D4, T4, A4, B4] = statEEG(coeff4);
    fprintf("Done\n");

    % Copy DWT features to X
    X = [X table2array(D1(:,1:end-1))]; 
    X = [X table2array(T1(:,1:end-1))]; 
    X = [X table2array(A1(:,1:end-1))]; 
    X = [X table2array(B1(:,1:end-1))];
    
    X = [X table2array(D2(:,1:end-1))]; 
    X = [X table2array(T2(:,1:end-1))]; 
    X = [X table2array(A2(:,1:end-1))]; 
    X = [X table2array(B2(:,1:end-1))];
    
    X = [X table2array(D3(:,1:end-1))]; 
    X = [X table2array(T3(:,1:end-1))]; 
    X = [X table2array(A3(:,1:end-1))]; 
    X = [X table2array(B3(:,1:end-1))];
    
    X = [X table2array(D4(:,1:end-1))]; 
    X = [X table2array(T4(:,1:end-1))]; 
    X = [X table2array(A4(:,1:end-1))]; 
    X = [X table2array(B4(:,1:end-1))];

    % ------------ Bicoherence Features ------------

    fprintf("Estimating bicoherence matrices ... ");
    [b1, f1] = bicEEG(Z,K,fs,fc,"EEGF4_M1","fast");
    [b2, f2] = bicEEG(Z,K,fs,fc,"EEGC4_M1","fast");
    [b3, f3] = bicEEG(Z,K,fs,fc,"EEGO2_M1","fast");
    [b4, f4] = bicEEG(Z,K,fs,fc,"EEGC3_M2","fast");
    fprintf("Done\n");

    fprintf("Extracting Features from bicoherence matrices ... ");
    Y1 = bicoherFeatures(b1,f1);
    Y2 = bicoherFeatures(b2,f2);
    Y3 = bicoherFeatures(b3,f3);
    Y4 = bicoherFeatures(b4,f4);
    fprintf("Done\n");

    % Copy bicoherence features to X
    X = [X table2array(Y1(:,1:end-1))]; 
    X = [X table2array(Y2(:,1:end-1))]; 
    X = [X table2array(Y3(:,1:end-1))]; 
    X = [X table2array(Y4(:,1:end-1))];

    % ---------------- QPC features ----------------
    fprintf("Locating QPC frequency-pairs ... ");
    qpc1 = findQPC(b1);
    qpc2 = findQPC(b2);
    qpc3 = findQPC(b3);
    qpc4 = findQPC(b4);
    fprintf("Done\n");

    fprintf("Extracting QPC features ... ");
    Y1 = QPCfeatures(qpc1,f1);
    Y2 = QPCfeatures(qpc2,f2);
    Y3 = QPCfeatures(qpc3,f3);
    Y4 = QPCfeatures(qpc4,f4);
    fprintf("Done\n");

    % Copy QPC features to X
    X = [X table2array(Y1(:,1:end-1))]; 
    X = [X table2array(Y2(:,1:end-1))]; 
    X = [X table2array(Y3(:,1:end-1))]; 
    X = [X table2array(Y4(:,1:end-1))];

    % ------------- Cepstrum Features --------------
    fprintf("Extracting cepstral features ... ");
%     [rc01, rc02, rc03, rc04] = rcepFeatures(Z, "EEGF4_M1");
%     [rc05, rc06, rc07, rc08] = rcepFeatures(Z, "EEGC4_M1");
%     [rc09, rc10, rc11, rc12] = rcepFeatures(Z, "EEGO2_M1");
    [rc13, rc14, rc15, rc16] = rcepFeatures(Z, "EEGC3_M2");
    fprintf("Done\n");

    % Copy cepstral features to X
%     X = [X table2array(rc01(:,1:end-1))]; 
%     X = [X table2array(rc02(:,1:end-1))]; 
%     X = [X table2array(rc03(:,1:end-1))]; 
%     X = [X table2array(rc04(:,1:end-1))]; 
%     X = [X table2array(rc05(:,1:end-1))]; 
%     X = [X table2array(rc06(:,1:end-1))]; 
%     X = [X table2array(rc07(:,1:end-1))];
%     X = [X table2array(rc08(:,1:end-1))]; 
%     X = [X table2array(rc09(:,1:end-1))]; 
%     X = [X table2array(rc10(:,1:end-1))]; 
%     X = [X table2array(rc11(:,1:end-1))]; 
%     X = [X table2array(rc12(:,1:end-1))]; 
    X = [X table2array(rc13(:,1:end-1))]; 
    X = [X table2array(rc14(:,1:end-1))]; 
    X = [X table2array(rc15(:,1:end-1))]; 
    X = [X table2array(rc16(:,1:end-1))]; 

    % -------------- EOG/EMG features --------------
    fprintf("Extracting EOG/EMG features ... ");
    Y = features_EOG_EMG(Z,true);
    X = [X single(Y{:,1})];
    fprintf("Done\n");

	% Save extracted features to disk
	fprintf("Saving extracted features to disk ... ");
	filename = sprintf("%s\\%d.mat", path, n);
	save(filename, "X", "y");
	fprintf("Done\n\n");

    toc;
end