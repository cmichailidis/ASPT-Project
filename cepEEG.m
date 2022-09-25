% =========================================================
% Author: Demetrios Orphanos, Christodoulos Michaelides
% Date: September 24th, 2022
% ---------------------------------------------------------
%
% Function Description:
% This function estimates the cepstral coefficients of
% EEG and/or ECG recordings
% ---------------------------------------------------------
%
% Arguments List:
%
% Z: (table) a table which contains EEG and/or ECG
% recordings. You should use loadEDF() to obtain this
% table.
%
% fs: (int or float) the sampling frequency of the EEG/ECG
% recordings in Hertz
%
% dt: (int or float) the duration of every EEG/ECG
% partition in seconds. loadEDF() splits the input
% signal in 30sec epochs. However, we may wish to estimate
% the cepstral coefficients in smaller partitions and average
% them to obtain a final estimation for the entire 30sec epoch.
% The duration of those partitions (in seconds) is
% determined by choosing an appropriate value for dt.
%
% channel: (int or string) the selected EEG/ECG channel.
% You can refer to a channel either by its name (eg "ECG",
% "ECGC3_M2") or by its column index in table Z.
% ---------------------------------------------------------
%
% Return Variables:
%
% C: (table) a table with 2 columns. The first column
% contains 1D-vectors of cepstral coefficients and the
% second column contains the sleep stage Annotations of
% its corresponding 1D-vector.
%
% t: (1D array of floats) quefrency axis of the estimated
% cepstral coefficients (in seconds).
% ---------------------------------------------------------
%
% Example:
%
% 1) Select the ECG recording of the 3rd patient
% 2) Use a 5sec window (6 partitions per 30sec epoch)
% 3) Estimate the cepstral coefficients in every 5sec window
% 4) Display the results
%
% >> patient_ID = 3;
% >> dt = 5.0;
% >> fs = 256;
% >> channel = "EEGC3_M2";
% >> Z = loadEDF(patient_ID);
% >> [C, ~] = cepEEG(Z, dt, fs, channel);
% >> disp(C)
% =========================================================

function [C, t] = cepEEG(Z, fs, dt, channel)
    % N: (int) number of 30sec EEG/ECG epochs
    % K: (int) number of partitions per epoch
    % M: (int) number of samples per partition
    N = size(Z,1);
    K = floor(30/dt);
    M = floor(dt * fs);
    
    % epsilon: (float) small positive constant
    % for numerical stability in floating point
    % operations (such as division etc ...)
    % epsilon = 1e-4;
    
    % quefrency axis in seconds
    t = linspace(0, dt, M);
    
    % C: (table) table of cepstral coefficients
    % sz: (1x2 array of ints) dimensions of C (rows x columns)
    % names: (array of strings) column names of C
    % types: (array of strings) variable types of C
    sz = [N 2];
    names = ["ceps" "Annotations"];
    types = ["cell" "string"];
    
    C = table(                  ...
        'Size',           sz,     ...
        'VariableNames',  names,  ...
        'VariableTypes',  types);
    
    for n = 1:N
        % Extract a 30sec EEG/ECG epoch
        x = cell2mat(Z{n,channel}); x = x(:);
    
        % Partition into K segments of M samples
        x = reshape(x(1:(K*M)), [M K]);
    
        % Normalize and apply a window function
        % x = (x - mean(x,1)) ./ (std(x,[],1) + epsilon);
        x = x .* hanning(M);
    
        % Estimate cepstral coefficients for every partition
        cc = zeros(M, 1);

        for k = 1:1:K
            cc = cc + cceps(x(:,k));
        end

        % Save the result
        C{n,"ceps"} = {cc / K};

        % Copy sleep stage Annotations
        C{n,"Annotations"} = Z{n,"Annotations"};
    end
end