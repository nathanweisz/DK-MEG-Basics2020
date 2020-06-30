clear all
restoredefaultpath

addpath('~/Documents/MATLAB/fieldtrip/')
ft_defaults


%%

datapath='~/Dropbox/Teaching/Salzburg/PhD/Fieldtrip_2020/Data/';
epoch_file='epochs.mat';

load(fullfile(datapath, epoch_file))

%% Add bit on trial
trialnums = [length(find(alldata.trialinfo == 2)), ...
                length(find(alldata.trialinfo == 4 | alldata.trialinfo == 5)), ...
                length(find(alldata.trialinfo == 8 | alldata.trialinfo == 9))];
          
ind_inf_low = find(alldata.trialinfo == 4 | alldata.trialinfo == 5);
ind_inf_low_300 = ind_inf_low(randsample(600, 300));

ind_inf_high = find(alldata.trialinfo == 8 | alldata.trialinfo == 9);
ind_inf_high_300 = ind_inf_high(randsample(600, 300));

%%

cfg=[];
cfg.toilim =[0 1];
tmpallpdata_short = ft_redefinetrial(cfg, alldata);

cfg              = [];
cfg.output       = 'pow';
cfg.method       = 'mtmfft';
cfg.taper        = 'hanning';
cfg.foi          = 4:1:30;                          

cfg.trials = find(alldata.trialinfo == 2)'; %all uninformative trials
powU= ft_freqanalysis(cfg,  tmpallpdata_short);

cfg.trials = [ind_inf_low_300; ind_inf_high_300]'; %selection informative
powI= ft_freqanalysis(cfg,  tmpallpdata_short);

powU = ft_combineplanar([],powU);
powI = ft_combineplanar([],powI);

clear tmpallpdata_short

%%

cfg=[];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
ft_multiplotER(cfg, powU, powI)

%%

powD = powU;
powD.powspctrm = log10(powI.powspctrm ./ powU.powspctrm);

cfg=[];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
ft_multiplotER(cfg, powD)

%%

cfg              = [];
cfg.output       = 'pow';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 4:1:30;                          
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;  
cfg.toi          = -.4:.05:1;               

cfg.trials = find(alldata.trialinfo == 2)'; %all uninformative trials
tfrU= ft_freqanalysis(cfg,  alldata);

cfg.trials = [ind_inf_low_300; ind_inf_high_300]'; %selection informative
tfrI= ft_freqanalysis(cfg,  alldata);

tfrU = ft_combineplanar([],tfrU);
tfrI = ft_combineplanar([],tfrI);

%%

cfg=[];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
cfg.baseline = [-.4 -.1];
cfg.baselinetype = 'relchange';
cfg.zlim = 'maxabs';
ft_multiplotTFR(cfg, tfrI)

%%

tfrD = tfrI;
tfrD.powspctrm = log10(tfrI.powspctrm ./ tfrU.powspctrm);

cfg=[];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
cfg.zlim = 'maxabs';
ft_multiplotTFR(cfg, tfrD)


%%


cfg              = [];
cfg.output       = 'pow';
cfg.method       = 'mtmconvol';
cfg.taper        = 'dpss';
cfg.foi          = 35:5:90;     
cfg.tapsmofrq    = linspace(5, 10, length(cfg.foi));
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.3;  
cfg.toi          = -.4:.05:1;               

cfg.trials = find(alldata.trialinfo == 2)'; %all uninformative trials
tfrU_h= ft_freqanalysis(cfg,  alldata);

cfg.trials = [ind_inf_low_300; ind_inf_high_300]'; %selection informative
tfrI_h= ft_freqanalysis(cfg,  alldata);

tfrU_h = ft_combineplanar([],tfrU_h);
tfrI_h = ft_combineplanar([],tfrI_h);

%%

cfg=[];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
cfg.baseline = [-.4 -.1];
cfg.baselinetype = 'db';
cfg.zlim = 'maxabs';
ft_multiplotTFR(cfg, tfrI_h)

%%

tfrD_h = tfrI_h;
tfrD_h.powspctrm = log10(tfrI_h.powspctrm ./ tfrU_h.powspctrm);

cfg=[];
cfg.layout='neuromag306cmb_helmet.lay'; %Note that the layout changed
cfg.zlim = 'maxabs';
ft_multiplotTFR(cfg, tfrD_h)






