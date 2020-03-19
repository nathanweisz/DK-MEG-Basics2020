
clear all
restoredefaultpath

addpath('~/Documents/MATLAB/fieldtrip/')
ft_defaults


%%

datapath='~/Dropbox/Teaching/Salzburg/PhD/Fieldtrip_2020/Data/';
fifname_max='19890425HRWL_block*_trans_sss.fif';

nn = dir(fullfile(datapath, fifname_max));

%%
cfg=[];
cfg.dataset=fullfile(datapath, nn(1).name);
cfg.trialdef.eventtype  = '?';
ft_definetrial(cfg);

%%

evt = ft_read_event(fullfile(datapath, nn(1).name));
evt = ft_filter_event(evt, 'type', 'Trigger');

%%
tmp=struct2cell(evt);
evt_ind=cell2mat(tmp(3,:));
evt_sample=cell2mat(tmp(2,:));

evt_ind = evt_ind(2:end);
evt_sample = evt_sample(2:end);

%%

hdr=ft_read_header(fullfile(datapath, nn(1).name));
ind_trigger=find(evt_ind == 2 | evt_ind == 4 | evt_ind == 5 | evt_ind == 8 | evt_ind == 9);

pointspre = hdr.Fs * 1;
pointspost = hdr.Fs * 1.5;

trl_manual = [evt_sample(ind_trigger)-pointspre; evt_sample(ind_trigger)+pointspost; -ones(1, length(ind_trigger))*pointspre];
trl_manual = trl_manual'; %this is basic trl matrix with epoch infos
trl_manual= [trl_manual, evt_ind(ind_trigger)']; % add trigger values

%%

cfg = [];
cfg.dataset = fullfile(datapath, nn(1).name);
cfg.trialdef.prestim = 1; % seconds % adjusted with 41 ms
cfg.trialdef.poststim = 1.5; % seconds
cfg.trialdef.eventvalue = [2 4 5 8 9];
cfg.trialdef.eventtype = 'Trigger';
    
cfg = ft_definetrial(cfg);

trl_ft = cfg.trl(2:end, :); % discard the first event (block type)


%%

load(fullfile(datapath, 'icacomps.mat'))

for ii = 1:length(nn)
    
    %READ CONTINUOUS DATA
    cfg = [];
    cfg.continuous = 'yes';
    cfg.channel='MEG';
    cfg.hpfilter='yes';
    cfg.hpfreq=1;
    cfg.lpfilter='yes';
    cfg.lpfreq=100;
    
    cfg.dataset     = fullfile(datapath, nn(ii).name);
    tmp       = ft_preprocessing(cfg);
    
    %APPLY ICA CLEANING
    cfg=[];
    cfg.component=bad;
    tmp=ft_rejectcomponent(cfg, comps, tmp);
    
    %MAKE TRL MATRIX
    cfg = [];
    cfg.dataset = fullfile(datapath, nn(ii).name);
    cfg.trialdef.prestim = 1; % seconds % adjusted with 41 ms
    cfg.trialdef.poststim = 1.5; % seconds
    cfg.trialdef.eventvalue = [2 4 5 8 9];
    cfg.trialdef.eventtype = 'Trigger';
    
    cfg = ft_definetrial(cfg);
    
    trl_ft = cfg.trl(2:end, :);
    
    %CHOP DATA AND COLLECT IN CELL STRUCTURE
    cfg=[];
    cfg.trl = trl_ft;
    data{ii} = ft_redefinetrial(cfg, tmp);
    
    %DOWNSAMPLE TO SPEED UP ANALYSIS LATER
    cfg=[];
    cfg.resamplefs=256;
    data{ii} = ft_resampledata(cfg, data{ii});

    
    clear tmp
end %nn

%%
alldata = ft_appenddata([], data{:}); clear data;

save(fullfile(datapath, 'epochs.mat'), 'alldata', '-v7.3')



