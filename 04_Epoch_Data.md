[TOC]

# The general idea

While some analysis would / could be done of the continuous raw data (e.g. resting state analysis of power in different frequency bands), in most cases analysis in our cognitive neuroscientific experiments is centered on events that you define: i.e. *what* happened and *when* did it happen? The what is usually a stimulus that was presented or a response by the participant, that are marked as triggers in your continuous data. In some cases this could be a combination of events, requiring some coding that checks trigger combinations (e.g. a stimulus X only when the following response was Y). Another -albeit more rare- possibility is to define physiological events (e.g. eye movements or distinct brain responses). **Whatever you are interested in, if you want to analyse epochs around certain events, then you will need to explicitly tell fieldtrip how to chop up the data**.

There are different flavours how this can be achieved. But in the end it boils down to two important steps:

1. When did an event happen and how much data (all in sampling points) do you want to cut around it?
2. What happened and additional information for the specific event that could be interesting?

The way fieldtrip organizes this information is in a so-called *trl*-matrix. This matrix is organized in a manner that each row is an event that you want an epoch for. The matrix require as a minimum three columns: the first / second mark beginning / end of epoch and the third marks the prestimulus time. You can add as many further columns as you want, e.g.: a fourth containing the actual trigger values (e.g. so I know which stimulus was presented) or behavioural data (e.g. RT, correct / incorrect). These additional columns are later stored in a field of your data structure labeled as *'.trialinfo'*. This can then later be used for conditional analysis, e.g. only condition X when answer was correct. Another neat option is that Fieldtrip does the bookkeeping for you, i.e. when you decide to later remove trials, then the *'.trialinfo'* is updated as well fascilitating a match between your data structure field containing the data and the useful information about each trial. **It is good practice to add as much information to each trial as possible right at the beginning of your data analysis.**

Getting a *trl*-matrix can be achieved in many ways and then passed on to epoch the data, e.g.:

> If you only have pre-defined triggers without fancy smart combination of events etc:
>
> * *ft_definetrial* (calling *ft_trialfun_general*) followed by *ft_preprocessing*
>
> If the definition of you events is more complicated then you will need to implement your own trial-function.
>
> * your *ft_trialfun_xxx* (that returns a *trl*-matrix) followed by *ft_preprocessing*
>
> If you have already continuous data read then you can also use *ft_redefinetrial* instead of *ft_preprocessing*.



# Let's try it on our data

As always we kick off with the following lines.

```matlab
clear all
restoredefaultpath

addpath('~/Documents/MATLAB/fieldtrip/')
ft_defaults
```

We have 6 fif-files containing MEG data during our attention experiment. The next lines collects the fif-file names.

```matlab
datapath='~/Dropbox/Teaching/Salzburg/PhD/Fieldtrip_2020/Data/';
fifname_max='19890425HRWL_block*_trans_sss.fif';

nn = dir(fullfile(datapath, fifname_max));
```

So to check the name of the first fif-file:

```matlab
>> nn(1).name

ans =

    '19890425HRWL_block01_trans_sss.fif'
```

## The events

Obviously, being a smart experimenter you know what was presented, i.e. which triggers you used. But let's check what fieldtrip finds for one of the fif-files.

```matlab
cfg=[];
cfg.dataset=fullfile(datapath, nn(1).name);
cfg.trialdef.eventtype  = '?';
ft_definetrial(cfg);
```

You will see a lot of output and among other things something like this.

```matlab
event type: 'Trigger' 
with event values: 2    4    5    8    9   16   32   64  128  129
```

From Patrick / Juliane's docs this is the info on the triggers:

```matlab
   % Triggerinfo:
    % -----------
    % Condition = 1st trigger at the beginning of every block
    % High tone square = 1
    % High tone circle = 2
    %
    % Cues: 
    % High tone cue valid = 8
    % High tone cue invalid = 9
    % High tone cue no target = 9
    %
    % Low tone cue valid = 4
    % Low tone cue invalid = 5
    % Low tone cue no target = 5

    % Uninformative cue high tone target = 2
    % Uninformative cue low tone target = 2
    % Uninformative cue no target = 2

    % Sounds:
    % High tone target = 64
    % Low tone target = 32
    % No tone target = 16

    % Responses:
    % correct response = 128
    % incorrect response = 129
```

As you can see, the analysis could go down many routes, but we want to make it simple and compare neural dynamics in a cue-target period when it was either informativ or uninformative. I.e. we do not care whether the cue was actually valid or (for this tutorial) whether the later response was correct. This means what we want to get are events 8/9, 4/5 and 2.

## Getting a *trl*

For the sake of it let's start by creating a matrix for block 1 *by hand*. We start by reading the events.

```matlab
evt = ft_read_event(fullfile(datapath, nn(1).name));
evt = ft_filter_event(evt, 'type', 'Trigger');
```

This structure has several fields that would be used to create a *trl*-matrix.

```matlab
>> evt

evt = 

  902×1 struct array with fields:

    type
    sample
    value
    offset
    duration
```

Two fields are especially important, '*value*' which contains the trigger-values in the sequence they were recorded and '*sample*' which is the onset of the trigger in sampling points. The information is organized somewhat awkwardly in cell. We can use following code to get a vector for this infomation.

```
tmp=struct2cell(evt);
evt_ind=cell2mat(tmp(3,:));
evt_sample=cell2mat(tmp(2,:));
```

Since the first event in a block indicates which visual shape was used for the high tone cue we will discard this event.

```matlab
evt_ind = evt_ind(2:end, :);
evt_sample = evt_sample(2:end, :);
```

Now we want to define epochs starting 1 second before the cue and lasting to 1.5 s following the cue (in general it is a good idea to be generous in terms of time and narrow down windows later). Since the relevant bits of information are in sampling points, we need to know the sampling rate. It is a good idea to take it from the fif-file, as you may change some recording settings and don't remember.

```matlab
hdr=ft_read_header(fullfile(datapath, nn(1).name));
ind_trigger=find(evt_ind == 2 | evt_ind == 4 | evt_ind == 5 | evt_ind == 8 | evt_ind == 9);

pointspre = hdr.Fs * 1;
pointspost = hdr.Fs * 1.5;

trl_manual = [evt_sample(ind_trigger)-pointspre; evt_sample(ind_trigger)-pointspost; -ones(1, length(ind_trigger))*pointspre];
trl_manual = trl_manual'; %this is basic trl matrix with epoch infos
trl_manual= [trl_manual, evt_ind(ind_trigger)']; % add trigger values
```

You could also do it using fieldtrip's *ft_definetrial* which perhaps is more convenient for simple analysis.

```matlab
cfg = [];
cfg.dataset = fullfile(datapath, nn(1).name);
cfg.trialdef.prestim = 1; % seconds % adjusted with 41 ms
cfg.trialdef.poststim = 1.5; % seconds
cfg.trialdef.eventvalue = [2 4 5 8 9];
cfg.trialdef.eventtype = 'Trigger';
    
cfg = ft_definetrial(cfg);

trl_ft = cfg.trl(2:end, :); % discard the first event (block type)
```

## Read data from all blocks

The following code snippet uses what we learned before and simply loops it across the blocks.

> This is takes quite a while. If you can't wait then download the data [here](https://www.dropbox.com/s/idohk28wk72b2i6/epochs.mat?dl=0).

```matlab
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
```

> We do the downsampling following the epoching. What would be the problem if we did it before on the continuous data?

Now we can concatenate the cells into one preprocessing structure and save the output.

```matlab
alldata = ft_appenddata([], data{:}); clear data;

save(fullfile(datapath, 'epochs.mat'), 'alldata', '-v7.3')
```

> Note: Since most calculations are done on the cluster we ususally do not save epoched data anymore. 