function [ smap ] = run( img_path, params )
    if nargin<1,img_path='input_test/72.png'; end
    if nargin<2, 
        
        %0.A. Initial Resize Params
        params.rsz=1; %resize factor
        
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
        params.fcs_params.eCSF_type='Xavier'; %other: Naila
        
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
        params.fg_name='gaussian';
        params.fg_params=struct();
        params.fg_params.W=35; %pxva
        
    end
    
    %% Include folders
     addpath(genpath('feature_extraction'));
     addpath(genpath('feature_conspicuity'));
     addpath(genpath('feature_integration'));
    
    %% Read image
    img=imread(img_path);
    img=double(img)/255;
     
    
    %% Resize img
    if params.rsz~=1 %rsz=resize factor, if 1 then do not resize
        img=imresize(img,1/params.rsz);
    end
    [M,N,C]=size(img);
    
    %% 1. Feature extraction 
    % 1.A. Color transform 
    switch(params.fc_name)
        case 'cielab'
            img=get_the_cstimulus(img,params.fc_params.gamma,params.fc_params.srgb_flag);
            fc_maps=img;
        case 'macleod-boynton'
            ... %to do 
                %https://github.com/dberga/sig4vam/tree/master/stimulusCode/color/colourspaces_akbarinia
                %https://github.com/dberga/sig4vam/tree/master/stimulusCode/color/other
                %https://isp.uv.es/code/visioncolor/colorlab.html#download
        otherwise
            fc_maps=img; %no transform, keep rgb components
    end
    %imagesc(fc_maps(:,:,1)); %debug: (:,:,channel)
    
    % 1.B. Multiresolution transforms
    for c=1:size(fc_maps,3)
        switch(params.fe_name)
            case 'a_trous'
                [wavelet_coeff{c},residual{c}]=a_trous(fc_maps(:,:,c),params.fe_params.wlev);
                fe_maps=wavelet_coeff;
            case 'DWT'
                [wavelet_coeff{c},residual{c}]=DWT(fc_maps(:,:,c),params.fe_params.wlev);
                fe_maps{c}=wavelet_coeff{c};
            case 'Gabor'
                ... %feature_extraction/multires/GaborTransform_XOP.m
            case 'logGabor'
                ... %to do (extraer del codigo de AWS)
            case 'curvelets'
                ... %feature_extraction/multires/fdct_wrapping.m
            case 'DoG'
                ... %to do, seguro que se encuentra en internet
            case 'HoG'
                ... %to do, seguro que se encuentra en internet
            otherwise 
                fe_maps=fc_maps; %no transform, keep color space
        end
    end
    %imagesc(fe_maps{1}{4}(:,:,1)); %debug: {channel}{scale}(:,:,orient)
    
    
    %% 2. Feature Saliency
    
    % 2.A. Feature conspicuity computation
    for c=1:size(fc_maps,3)
        switch(params.fs_name)
            case 'center-surround'
                for s=1:length(fe_maps{c})
                    for o=1:size(fe_maps{c}{s},3)
                        Zctr{c}{s,1}(:,:,o)=relative_contrast(fe_maps{c}{s}(:,:,o),o, params.fs_params.window_sizes);
                    end
                end
                fs_maps{c}=Zctr{c};
            otherwise
                fs_maps=fe_maps; %no transform, keep multiresolution feature maps
        end
    end
    %imagesc(fs_maps{1}{4}(:,:,1)); %debug: {channel}{scale}(:,:,orient)
    
    % 2.B. Contrast sensitivity function 
    for c=1:size(fc_maps,3)
        switch(params.fcs_name)
            case 'ecsf'
                for s=1:length(fs_maps{c})
                    for o=1:size(fs_maps{c}{s},3)
                        alpha=generate_csf(fs_maps{c}{s}(:,:,o), s, params.fcs_params.nu_0, params.fcs_params.modes{c},params.fcs_params.eCSF_type);
                        fcs_maps{c}{s,1}(:,:,o)=alpha;
                    end
                end
            otherwise
                fcs_maps=fs_maps;
        end
    end
    %imagesc(fcs_maps{1}{4}(:,:,1)); %debug: {channel}{scale}(:,:,orient)
    
    %% 3. Feature Integration
    % 3.A. Feature Fusion (integrate scale and orientation)
    for c=1:size(fc_maps,3)
        switch(params.fi_name)
            case 'inverse'
                if params.fi_params.residual2zero==true
                    for s=1:length(fs_maps{c}) %remove residuals, other: residual{c}
                        %residual{c}{s}=ones(size(residual{c}{s},1),size(residual{c}{s},2));
                        residual{c}{s}=zeros(size(residual{c}{s},1),size(residual{c}{s},2));
                    end
                end
                switch(params.fe_name)
                    case 'a_trous'
                        fi_map(:,:,c)=Ia_trous(fcs_maps{c},residual{c});
                    case 'DWT'
                        fi_map(:,:,c)=IDWT(fcs_maps{c},residual{c},N,M);
                    case 'logGabor'
                        ... %to do (extraer del codigo de AWS)
                    case 'curvelets' 
                        ... %feature_extraction/multires/ifdct_wrapping.m
                    end
            case 'max'
                ... %to do, similar a channelmax pero con mas dimensiones (scale and orient)
            case 'sum'
                ... %to do, sumar feature maps de escala y orientacion
            case 'max-likelihood'
                ... %to do
            otherwise 
                ... %max by default
        end
    end
    %nota: algunas transformadas son decimadas (piramidales), como por ejemplo el DWT.
    %Es decir, las matrices deben reescalarse antes de hacer cualquier operacion (ex. max, sum ...)
    
    %imagesc(fi_map(:,:,1)); %debug: (:,:,channel)
    
     % 3.B. Chromatic Fusion (integrate chromatic channels)
    switch(params.ffc_name)
            case 'sqmean'  %euclidean norm.
                ffc_map=sqrt(sum(fi_map.^2,3));
            case 'avg'
                ... %feature_integration/fusion/channelmax
            case 'wta' %select whole RF where activity is maximum
                ... %feature_integration/fusion/channelwta.m
            case 'max'  %select maximum per each pixel
                ... %feature_integration/fusion/channelmax.m
    end
    %imagesc(ffc_map) %debug
    
    %% 4. Normalization and smoothing
    
    % 4.A. Saliency Map Normalization
    switch(params.fn_name)
        case 'energy'
            fn_map=normalize_energy(ffc_map);
        case 'range'
            ... %feature_integration/normalization/normalize_range.m
        case 'minmax'
            ... %feature_integration/normalization/normalize_minmax.m
        case 'minmax_clampzeros'
            ... %feature_integration/normalization/normalize_minmaxp.m
        case 'variance'
            ... %feature_integration/normalization/normalize_Z.m
        case 'variance_clampzeros'
            ... %feature_integration/normalization/normalize_Zp.m
        otherwise
            fn_map=ffc_map;
    end
    %imagesc(fn_map) %debug
    
    % 4.B. Smoothing 
    switch(params.fg_name)
        case 'gaussian'
            fg_map=zhong2012(fn_map,params.fg_params.W);
        otherwise %none
            fg_map=fn_map; %no smoothing
    end
    %imagesc(fg_map) %debug

    %finally normalize to get 0-1 map (to write/show image)
    smap=normalize_minmax(fg_map);
    imagesc(smap)
    
end

