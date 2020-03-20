
clear all
restoredefaultpath

addpath('~/Documents/MATLAB/fieldtrip/')
ft_defaults


%%

datapath='~/Dropbox/Teaching/Salzburg/PhD/Fieldtrip_2020/Data/';
epoch_file='epochs.mat';

load(fullfile(datapath, epoch_file))

%% Average over all trials

cfg=[];
evoked_all = ft_timelockanalysis(cfg, alldata);

%%

cfg=[];
cfg.xlim = [-.2 1.4];
cfg.layout='neuromag306mag_helmet.lay';
ft_multiplotER(cfg, evoked_all)

%%
cfg=[];
cfg.preproc.lpfilter = 'yes';
cfg.preproc.lpfreq = 30;
evoked_all_lp = ft_timelockanalysis(cfg, alldata);

%%

cfg=[];
cfg.xlim = [-.2 1.4];
cfg.layout='neuromag306mag_helmet.lay';
ft_multiplotER(cfg, evoked_all, evoked_all_lp)

%%
cfg=[];
cfg.xlim = [-.2 1.4];
cfg.layout='neuromag306mag_helmet.lay';
ft_multiplotER(cfg, evoked_all_lp)

%%
cfg=[];
evoked_all_lp_cmb = ft_combineplanar(cfg, evoked_all_lp);

cfg=[];
cfg.xlim = [-.2 1.4];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
ft_multiplotER(cfg, evoked_all_lp_cmb)

%%

trialnums = [length(find(alldata.trialinfo == 2)), ...
                length(find(alldata.trialinfo == 4 | alldata.trialinfo == 5)), ...
                length(find(alldata.trialinfo == 8 | alldata.trialinfo == 9))]
            
%%

ind_inf_low = find(alldata.trialinfo == 4 | alldata.trialinfo == 5);
ind_inf_low_300 = ind_inf_low(randsample(600, 300));

ind_inf_high = find(alldata.trialinfo == 8 | alldata.trialinfo == 9);
ind_inf_high_300 = ind_inf_high(randsample(600, 300));

%% WEIRD ... SEEMS NOT TO DO SUBSELECTION ?? 
cfg=[];
cfg.preproc.lpfilter = 'yes';
cfg.preproc.lpfreq = 30;

cfg.trials = find(alldata.trialinfo == 2)'; %all uninformative trials
avg_U = ft_timelockanalysis(cfg, alldata);


cfg=[];
cfg.trials = [ind_inf_low_300; ind_inf_high_300]'; %selection informative
avg_I = ft_timelockanalysis(cfg, alldata);

%% baseline subtraction

cfg=[];
cfg.baseline = [-.1 0];

avg_U = ft_timelockbaseline(cfg, avg_U);
avg_I = ft_timelockbaseline(cfg, avg_I);

avg_U = ft_combineplanar([], avg_U);
avg_I = ft_combineplanar([], avg_I);

%%

cfg=[];
cfg.xlim = [-.2 1];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
ft_multiplotER(cfg, avg_U, avg_I)

%%

avg_diff = avg_U;
avg_diff.avg = avg_I.avg - avg_U.avg;

cfg=[];
cfg.xlim = [-.2 .5];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
ft_multiplotER(cfg, avg_diff)

