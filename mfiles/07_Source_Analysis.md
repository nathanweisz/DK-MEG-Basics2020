



# Why source analysis?



XXXX



# The ingredients for source analysis



# Now you don't have an MRI ...



```matlab
restoredefaultpath
clear all


addpath('~/.CMVolumes/Obob/obob/obob_ownft_new/') %ADD YOUR PATH TO OBOB_OWNFT

cfg = [];
obob_init_ft(cfg); 


datapath='~/Dropbox/Teaching/Salzburg/PhD/Fieldtrip_2020/Data/';

grad = ft_read_sens(fullfile(datapath, '19890425HRWL_block01_trans_sss.fif'));

%%
grad = ft_convert_units(grad, 'm');

cfg = [];
cfg.headshape = fullfile(datapath, '19890425HRWL_block01_trans_sss.fif');
cfg.mrifile = [];
cfg.sens = grad;
 
[mri_aligned, headshape, hdm, mri_segmented] = obob_coregister(cfg);

save(fullfile(datapath, 'headstuff4DK2020.mat'), 'mri_aligned', 'hdm')
```



JUST DO IT THE OBOB WYA