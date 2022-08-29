% =======================================================
% Author Christodoulos Michaelides
% Date: August 25th, 2022
% -------------------------------------------------------
%
% Function Description: 
% This function can be used to extract features from the
% bispectrum estimations of EEG signals such as:
%   1) bispectrum entropy
%   2) bispectrum squared entropy
%   3) bispectrum cubed entropy
% -------------------------------------------------------
%
% Arguments List: (X, freq)
% X: (table) a table with two columns. The first should
% contain the bispectrum estimations and the
% second should contain the sleep stage Annotations.
% You should use bisEEG to obtain this table.
% -------------------------------------------------------
%
% Return List: (Y)
%
% TODO: add text
% =======================================================

function [Y] = bispectrumFeatures(X)
    % Number of EEG segments (30sec epochs)
    N = size(X,1);

    % Initialize an empty table to store
    % features from the bispectrum matrices.
    types = ["double", "double", "double", "double", "double" "string"];
    names = ["ent1", "ent2", "ent3", "H1", "H2", "Annotations"];

    Y = table(                      ...
        'Size',          [N 6],     ...
        'VariableTypes', types,     ...
        'VariableNames', names);

    % A small positive constant to ensure 
    % numerical stability when performing 
    % divisions.
    epsilon = 1e-5;

    for i = 1:1:N
        % Extract the entire bispectrum
        % matrix for a 30sec EEG segment
        % and normalize it
        bis = cell2mat(X{i,1}); 
        bis = abs(bis); 
        b   = bis / (max(bis(:)) + epsilon);
        
        % Estimate bispectrum entropies
        p = b(:).^1;
        Y{i,"ent1"} = -sum(p.*log2(p),'omitnan');
        q = b(:).^2;
        Y{i,"ent2"} = -sum(q.*log2(q),'omitnan');
        r = b(:).^3;
        Y{i,"ent3"} = -sum(r.*log2(r),'omitnan');

        % Estimate bispectrum log averages
        Y{i,"H1"} = sum(log2(bis(:) + epsilon));
        Y{i,"H2"} = sum(log2(diag(flip(bis + epsilon))));
    end

    % Copy sleep stage Annotations;
    Y.Annotations = X.Annotations;
end