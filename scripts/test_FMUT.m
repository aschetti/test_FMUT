
%% SETUP

rng(9001); % seed for pseudo-random number generator (it's over 9000!)

% functions & toolboxes
addpath '/home/aschetti/Documents/Projects/test_FMUT/scripts/functions/'; % misc functions
addpath '/home/aschetti/Documents/MATLAB/toolboxes/FMUT_0.5.1'; % Factorial Mass Univariate ERP Toolbox (FMUT)
addpath '/home/aschetti/Documents/MATLAB/toolboxes/eeglab2020_0'; % EEGLAB

% directories
path_project = '/home/aschetti/Documents/Projects/test_FMUT/'; % project directory
pathdata_raw = [path_project 'data/raw/']; % where to get the .bdf files
pathdata_preproc = [path_project 'data/preproc/']; % where to store the preprocessed data
pathdata_mass = [pathdata_preproc 'mass_univ/']; % where to store the binned data (for mass univariate analysis)
pathscripts = [path_project 'scripts/']; % where to retrieve and store the scripts
pathchanns = [pathscripts 'chanlocs/BioSemi68.locs']; % channel locations

% TRIGGERS:
% 4: negativeLargeDark
% 5: negativeSmallDark
% 6: negativeLargeBright
% 7: negativeSmallBright
% 8: neutralLargeDark
% 9: neutralSmallDark
% 10: neutralLargeBright
% 11: neutralSmallBright

begin_epoch = -200; % begin epoch (in ms)
end_epoch = 1000; % end epoch (in ms)

filenames_bdf = dir([pathdata_raw '*.bdf']); % read file names in folder path (puts it in a structure)

eeglab nogui; % necessary to load EEGLAB and Mass Univariate Toolbox functions

%% PREPROCESSING

for isub = 1:numel(filenames_bdf) % loop through participants
    
    % file name
    dispname = filenames_bdf(isub).name(1:end-4);
    
    % display participant number
    disp('***********************')
    disp(['Processing ' filenames_bdf(isub).name '...'])
    disp('***********************')
    
    % import .bdf files
    EEG = pop_biosig([pathdata_raw dispname '.bdf'], ...
        'channels', [1:68], ...          % 64 scalp channels + 4 ocular channels
        'ref', [48], ...                 % reference Cz
        'refoptions', {'keepref' 'on'});
    
    %     % check data
    %     pop_eegplot(EEG, 1, 1, 0);
    
    EEG = pop_chanedit(EEG, 'load', {pathchanns, 'filetype', 'autodetect'}); % assign channel locations
    % figure; topoplot([],EEG.chanlocs,'style','blank', 'electrodes','labelpoint','chaninfo',EEG.chaninfo); % plot channel locations
    
    EEG = eeg_detrend_widmann(EEG); % remove linear trends
    EEG = pop_eegfiltnew(EEG, [], 0.5, 1690, true, [], 0); % Hamming windowed sinc FIR filter, passband edge 0.5 Hz, filter order 1690 (estimated), transition bandwidth 0.5 Hz, cutoff frequency (-6 dB) 0.25 Hz
    EEG = pop_eegfiltnew(EEG, [], 30, 114, 0, [], 0); % Hamming windowed sinc FIR filter, passband edge 30 Hz, filter order 114 (estimated), transition bandwidth 7.4 Hz, cutoff frequency (-6 dB) 33.71 Hz
    
    originalEEG = EEG; % backup original EEG data before artifact correction
    
    % artifact correction via Artifact Subspace Reconstruction (see http://sccn.ucsd.edu/eeglab/plugins/ASR.pdf)
    EEG = clean_artifacts(EEG, ...
        'ChannelCriterion', .8, ...
        'LineNoiseCriterion', 3, ...
        'BurstCriterion', 5, ...
        'WindowCriterion', .2, ...
        'Highpass', 'off', ...
        'ChannelCriterionMaxBadTime', .5, ...
        'BurstCriterionRefMaxBadChns', .1, ...
        'BurstCriterionRefTolerances', [-3.5 5.5], ...
        'WindowCriterionTolerances', [-3.5 7], ...
        'FlatlineCriterion', 5);
    
    % unexplainably, the artifact detection routine deletes the event information from the EEG structure... but only for some participants.
    % To avoid problems, copy the event info from the original EEG structure.
    EEG.event = originalEEG.event; EEG.urevent = originalEEG.urevent;
    
    % vis_artifacts(EEG, originalEEG, 'NewColor', 'red', 'OldColor', 'black', 'DisplayMode', 'both'); % compare clean and raw data
    
    % interpolate discarded channels
    EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');
    
    % re-reference to average
    EEG = pop_select(EEG, 'nochannel', [65:68]); % remove ocular channels from data
    EEG = pop_reref(EEG, [], 'keepref', 'on'); % re-reference to average
    
    eeglab redraw; close; % redraw and close EEGLAB GUI (necessary to load ERPLAB)
    
    % create and edit EventList
    EEG = pop_editeventlist(EEG, ...
        'List', [pathscripts 'event_lists/EventList.txt'], ... % text file that contains edited event information
        'ExportEL', [pathscripts 'event_lists/' dispname '_EventList.txt'], ... % text file that will contain the event information
        'BoundaryString', {'boundary'}, ... % string code to be converted
        'BoundaryNumeric', { -99}, ... % numeric code that string code is to be converted to
        'SendEL2', 'All', ... % save EVENTLIST to text file, EEG structure, and workspace
        'UpdateEEG', 'code',... % copy EEG.EVENTLIST.eventinfo.code field values into EEG.event.type
        'AlphanumericCleaning', 'on', ... % delete alphabetic characters from alphanumeric event codes
        'Warning', 'off'); % do not warn if eventlist will be overwritten.
    
    % extract epochs (baseline-corrected)
    EEG = pop_epochbin(EEG, [begin_epoch end_epoch], 'pre');
    
    % save dataset with trial info
    pop_saveset(EEG, ...
        'filename', [dispname '_preproc.set'], ...
        'filepath', pathdata_preproc);
    
    % compute trial-averaged ERPs
    ERP = pop_averager(EEG, ...
        'Criterion', 'all', ... % include all epochs
        'Compute','ERP', ... % compute only averaged ERP
        'SEM','on', ... % include standard error of the mean
        'ExcludeBoundary','on', ... % exclude epochs with boundary events
        'Warning', 'off');
    
    % save trial-averaged ERPs
    pop_savemyerp(ERP, ...
        'erpname', dispname, ...
        'filename',[dispname '.erp'], ...
        'filepath', pathdata_mass, ...
        'Warning', 'off');
    
end

%% FMUT: DATA PREPARATION

% prepare file list for GND file
filenames_erp = dir([pathdata_mass '*.erp']); % read file names in folder path (puts it in a structure)

for isub = 1:numel(filenames_erp) % loop through participants
    
    filestr(isub,1)={[pathdata_mass filenames_erp(isub,1).name]}; % get location of all files to include in GND structure
    
end

% create the GND file
GND = erplab2GND(filestr, ...
    'exp_name', 'test_FMUT', ...
    'out_fname', 'no save');

save([pathdata_mass 'test_FMUT.GND']); % save GND file

% headinfo(GND) % see channels and bins of GND file
% gui_erp(GND) % check the data

%% FMUT: FACTORIAL ANALYSIS

% from the FMUT tutorial
% (https://github.com/ericcfields/FMUT/wiki/Mass-univariate-statistics-and-corrections#permutation-based-fmax):
% Permutation-based Fmax
% This correction uses a permutation approach to estimate the null distribution for Fmax --
% that is, the expected distribution of the largest F-value across the time points and electrodes of interest
% if the null hypothesis were true.
% Observed F-values exceeding the 1 - α percentile of the distribution are considered significant.
%
% The Fmax correction is conceptually similar to a Bonferroni or Šidák correction.
% In fact, if the values observed at each time point and electrode were statistically independent,
% the distribution of Fmax could be calculated from the Šidák inequality.
% However, the data at nearby electrodes and time points will be positively correlated;
% the permutation based Fmax approach will therefore provide a less severe correction (and greater power)
% while maintaining the Type I error rate.
%
% This provides strong family-wise error control:
% the maximum probability that you will commit a Type I error at even one electrode/time point is α.
% This means you can have confidence in each significant electrode/time point.
% The downside is that this test is relatively stringent:
% it will significantly underestimate the true spatial and temporal extent of an effect.
%
% In terms of detecting whether an effect exists at all (as opposed to accurately assessing its extent),
% the Fmax approach will generally have less power than the cluster mass approach
% for (spatially and temporally) widely distributed effects,
% but will have greater power for focal effects (see Simulation Results and Groppe et al., 2011b).

load([pathdata_mass 'test_FMUT.GND'], '-mat'); % load GND file

GND = FmaxGND(GND, ...
    'bins', 1:8, ... % use all bins
    'factor_names', {'Size' 'Contrast' 'Emotion'}, ... % names of factors in fastest to slowest moving order
    'factor_levels', [2, 2, 2], ...
    'n_perm', 5000, ...
    'alpha', 0.05, ...
    'plot_raster', 'no', ...
    'save_GND', 'no');

save([pathdata_mass 'test_FMUT.GND']); % save GND file

report_results(GND, 1) % show results in command window

% To interpret the results,
% see https://github.com/ericcfields/FMUT/wiki/Using-FMUT#output

%% FMUT: PAIRWISE FOLLOW-UP CONTRASTS

load([pathdata_mass 'test_FMUT.GND'], '-mat'); % load GND file

% TRIGGERS:
% 1: negativeLargeDark
% 2: negativeSmallDark
% 3: negativeLargeBright
% 4: negativeSmallBright
% 5: neutralLargeDark
% 6: neutralSmallDark
% 7: neutralLargeBright
% 8: neutralSmallBright

% bins
% main effect of emotion
GND = bin_mean(GND, [1:4], 'negative'); % bin 9

% ERROR: Unrecognized function or variable 'bin_mean'.

%%
