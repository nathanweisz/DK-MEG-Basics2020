%%
clear all
restoredefaultpath

addpath('~/Documents/MATLAB/fieldtrip/')
ft_defaults


%%

datapath='~/Dropbox/Teaching/Salzburg/PhD/Fieldtrip_2020/Data/';
fifname_max='19890425HRWL_resting_trans_sss.fif';

%% 

cfg = [];
cfg.continuous = 'yes';
cfg.channel='MEG';
cfg.hpfilter='yes';
cfg.hpfreq=1;
cfg.lpfilter='yes';
cfg.lpfreq=100;

cfg.dataset     = [datapath fifname_max];
data       = ft_preprocessing(cfg);

%% We can downsample for ICA

cfg=[];
cfg.resamplefs=256;
data = ft_resampledata(cfg, data);

%%
cfg=[];
cfg.channel='MEGMAG';
cfg.layout='neuromag306mag_helmet.lay';
cfg.viewmode='vertical';
ft_databrowser(cfg, data)

%%
cfg=[];
cfg.length=2; % chop out 2 second periods
ep4ica=ft_redefinetrial(cfg, data);

%%

cfg=[];
cfg.method = 'runica';
cfg.numcomponent = 60; % 50-60 components for our purposes
cfg.demean = 'yes';
comps = ft_componentanalysis(cfg, ep4ica);

%%
cfg=[];
cfg.layout='neuromag306mag.lay';
ft_databrowser(cfg, comps)

%% ecg1 = 6; ecg2 = 42??; blink 11
bad=[6 11 42];
save(fullfile(datapath, 'icacomps.mat'), 'comps', 'bad')

%%

cfg=[];
cfg.component=bad;
data_clean=ft_rejectcomponent(cfg, comps, data);

%%
cfg=[];
cfg.channel='MEGMAG';
cfg.layout='neuromag306mag_helmet.lay';
cfg.viewmode='vertical';
ft_databrowser(cfg, data_clean)


