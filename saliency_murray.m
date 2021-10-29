function [ smap ] = saliency_murray(input_image,image_path)
    if nargin<2, image_path='input_test/72.png'; end
    if nargin<1, image_path='input_test/72.png'; input_image=imread(image_path); end
    
    %% Set Parameters for this model (Murray et al. CVPR 2011)
    
    %0.A. Initial Resize Params
    params.rsz=2; %resize factor

    %1.A. Color Transform params
    params.fc_name='cielab';
    params.fc_params=struct();
    params.fc_params.srgb_flag=1; %apply cielab
    params.fc_params.gamma=2.4; %other: 2.2

    %1.B. Multiresolution Transform Params
    params.fe_name='DWT';
    params.fe_params=struct();
    params.fe_params.wlev=7; %number of scales
    %params.fe_params.wlev=min([7,floor(log2(min([M N])))]);

    %2.A. Feature Conspicuity Params
    params.fs_name='center-surround';
    params.fs_params=struct();
    params.fs_params.window_sizes=[13 26]; %other: [17 37]

    %2.B. eCSF Params
    params.fcs_name='ecsf';
    params.fcs_params=struct();
    params.fcs_params.modes={'colour','colour','intensity'};
    params.fcs_params.nu_0=4; %other: 2
    params.fcs_params.eCSF_type='Naila'; %other: Xavier

    %3.A. Multiresolution Fusion Params
    params.fi_name='inverse';
    params.fi_params=struct();
    params.fi_params.residual2zero=true;

    %3.B. Chromatic Fusion Params
    params.ffc_name='sqmean';
    params.ffc_params=struct();

    %4.A. Normalization Params
    params.fn_name='energy';
    params.fn_params=struct();

    %4.B. Smoothing Params
    params.fg_name='none';
    params.fg_params=struct();
    params.fg_params.W=35; %pxva
    
    %% Run model
    smap=run(image_path,params);
    
end

