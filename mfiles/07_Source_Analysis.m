
clear all
restoredefaultpath

addpath('~/Documents/GitHub/fieldtrip/')
ft_defaults;

%%

datapath='~/Dropbox/Teaching/Salzburg/PhD/Fieldtrip_2020/Data/';
epoch_file='epochs.mat';
head_file='headstuff4DK2020.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAKE GRID AND LEADFIELD
load(fullfile(datapath, head_file))
load(fullfile(datapath, epoch_file))

%%
alldata.grad=grad;

load standard_sourcemodel3d10mm.mat
alldata.grad = ft_convert_units(alldata.grad, 'm');
headshape=ft_convert_units(headshape, 'm');
mri_aligned=ft_convert_units(mri_aligned, 'm');
hdm=ft_convert_units(hdm, 'm');
sourcemodel=ft_convert_units(sourcemodel, 'm');

cfg           = [];
cfg.warpmni   = 'yes';
cfg.template  = sourcemodel;
cfg.nonlinear = 'yes';
cfg.mri       = mri_aligned;
cfg.unit      ='m';
grid          = ft_prepare_sourcemodel(cfg);

figure
hold on
ft_plot_headmodel(hdm, 'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;
ft_plot_mesh(grid.pos(grid.inside,:));
ft_plot_sens(alldata.grad);

%% compute leadfield

restoredefaultpath

addpath('~/Documents/GitHub/obob_ownft/')
obob_init_ft;

cfg = [];
cfg.grid = grid;
cfg.vol = hdm; % subject specific headmodel /volume
cfg.channel = 'MEG';
cfg.normalize = 'no'; % 'yes' or 'no'
 
lf = ft_prepare_leadfield(cfg, alldata);

save(fullfile(datapath, 'individual_grid.mat'), 'grid')
save(fullfile(datapath, 'individual_leadfield.mat'), 'lf')

clear mri_segmented

%%
cfg=[];
cfg.preproc.lpfilter='yes';
cfg.preproc.lpfreq=30;
cfg.covariancewindow=[-.5 1];
cfg.covariance='yes';
avg4fil=ft_timelockanalysis(cfg, alldata);

cfg=[];
cfg.grid=lf;
cfg.regfac='10%';
filt = obob_svs_compute_spat_filters(cfg, avg4fil);

clear avg4fil

cfg=[];
cfg.spatial_filter = filt;
alldataS = obob_svs_beamtrials_lcmv(cfg, alldata);

%% OVERALL EP

trialnums = [length(find(alldata.trialinfo == 2)), ...
                length(find(alldata.trialinfo == 4 | alldata.trialinfo == 5)), ...
                length(find(alldata.trialinfo == 8 | alldata.trialinfo == 9))]
            
%%

ind_inf_low = find(alldata.trialinfo == 4 | alldata.trialinfo == 5);
ind_inf_low_300 = ind_inf_low(randsample(600, 300));

ind_inf_high = find(alldata.trialinfo == 8 | alldata.trialinfo == 9);
ind_inf_high_300 = ind_inf_high(randsample(600, 300));

%%
clear alldata

%% WEIRD ... SEEMS NOT TO DO SUBSELECTION ?? 
cfg=[];
cfg.latency=[-.3 .6];
cfg.trials = find(alldataS.trialinfo == 2); %all uninformative trials
avg_U = ft_timelockanalysis(cfg, alldataS);

cfg=[];
cfg.latency=[-.3 .6];
cfg.trials = [ind_inf_low_300; ind_inf_high_300]; %selection informative
avg_I = ft_timelockanalysis(cfg, alldataS);

%%
cfg=[];
cfg.baseline=[-.3 0];
cfg.baselinetype = 'relchange';
avg_U_bl=obob_svs_timelockbaseline(cfg, avg_U);
avg_I_bl=obob_svs_timelockbaseline(cfg, avg_I);

%%
plot(avg_U_bl.time, sqrt(mean(avg_U_bl.avg.^2))); hold
plot(avg_U_bl.time, sqrt(mean(avg_I_bl.avg.^2)))
legend('Uninf', 'Inf')

%%

load standard_mri.mat

cfg=[];
cfg.latency=[.1 .22];
cfg.parameter='avg';
cfg.mri=mri;
cfg.sourcegrid = sourcemodel; %=template source model
S_avg_U_bl=obob_svs_virtualsens2source(cfg, avg_U_bl);
S_avg_I_bl=obob_svs_virtualsens2source(cfg, avg_I_bl);

%%

cfg = [];
cfg.method        = 'ortho';
cfg.funparameter  = 'avg';
cfg.maskparameter = cfg.funparameter;
cfg.funcolorlim   = [0.0 max(S_avg_I_bl.avg(:))];
ft_sourceplot(cfg, S_avg_U_bl);

cfg.funcolorlim   = [0.0 max(S_avg_I_bl.avg(:))];
ft_sourceplot(cfg, S_avg_I_bl);

%%

S_avg_Diff=S_avg_U_bl;
S_avg_Diff.avg=(S_avg_I_bl.avg-S_avg_U_bl.avg);

cfg = [];
cfg.method        = 'ortho';
cfg.funparameter  = 'avg';
cfg.maskparameter = cfg.funparameter;
cfg.funcolorlim   = [0.0 max(S_avg_Diff.avg(:))];
ft_sourceplot(cfg, S_avg_Diff);


%% [-32 -76 -5] ... MAXIMUM EVOKED RP

Dist2ROI=sourcemodel.pos(sourcemodel.inside,:) - repmat([-32 -76 -5]/1000, ... 
                size(sourcemodel.pos(sourcemodel.inside,:),1),1);

[mindist minind]=min(sqrt(sum(Dist2ROI.^2,2))); % find closest source

%%

cfg              = [];
cfg.channel      =  alldataS.label{minind};
cfg.output       = 'pow';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 4:1:30;                          
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;  
cfg.toi          = -.4:.05:1;               

tfrS= ft_freqanalysis(cfg,  alldataS);

%%

cfg=[];
cfg.baseline=[-.4 -.1];
cfg.baselinetype = 'relchange';
cfg.zlim='maxabs';
ft_singleplotTFR(cfg, tfrS)



