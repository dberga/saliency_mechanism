function [w c] = a_trous(image, wlev)
% Implementation of Mallate Discrete Wavelet Transform.
%
% outputs:
%   w: cell array of length wlev, containing wavelet planes in 3
%   orientations.
%   c: cell array of length c, containing residual planes.
%
% inputs:
%   image: input image to be decomposed.
%   wlev: # of wavelet levels.

% pad image so that dimensions are powers of 2:
aux_image=image;
image = add_padding(image);

% Defined 1D Gabor-like filter:
h = [1./16.,1./4.,3./8.,1./4.,1./16.];

energy = sum(h);
inv_energy = 1/energy;
h = h*inv_energy;
w = cell(wlev,1);
c = cell(wlev,1);

% disp(strcat('Nombre plans wavelet a la funcio a_trous: ', num2str(wlev)));
for s = 1:wlev
    img_dim = size(image,1);
    orig_image = image;
    inv_sum = 1/sum(h);
   
    % decimate image along horizontal direction
    prod = symmetric_filtering(image, h)*inv_sum;          % blur
    HF = prod;

	 GF = image - prod;                              % horizontal frequency info                            
    
    % decimate image along vertical direction   
    prod = symmetric_filtering(image, h')*inv_sum;            % blur
%     HHF = prod;
    GHF = image - prod;                                % vertical wavelet plane
   
    % decimate GF along vertical direction
     prod = symmetric_filtering(HF, h')*inv_sum;            % blur 
%    tmp_prod = zeros(size(prod));
%    tmp_prod(1:2:img_dim,:) = prod(1:2:img_dim,:);         % downsample
    
     HGF = prod;
	
    % save horizontal and vertical wavelet planes:
    w{s,1}(:,:,1) = GF;
    w{s,1}(:,:,2) = GHF;
   
    % Downsample residual image, HHF:
%    HHF = HHF(1:2:img_dim,1:2:img_dim);
   
   
   
    % Create and save wavelet plane:
    DF = orig_image - (HGF + GF + GHF);
    w{s,1}(:,:,3) = DF;

	 
    % save residual
    C      = image - (w{s,1}(:,:,1)+w{s,1}(:,:,2)+w{s,1}(:,:,3));
    c{s,1} = C;
	 image=C;
	 
	 
    % Downsample residual image:
%    image = HHF(1:2:img_dim,1:2:img_dim);
%	image=HHF;
	
	% Upsample filter
	h = [0 upsample(h,2)]; 
% 	h = upsample(upsample(h,2)',2)';
   
    
end

%unpad wavelet plane and residual
[w,c]=erase_padding_w(w,c,wlev,size(aux_image));

%% debug
% close all
% for s=1:wlev
%    for o=1:size(w{s,1},3)
%        figure,imagesc(w{s,1}(:,:,o));
%         title(['s=' num2str(s) ',o=' num2str(o)]);
% %         rf=w{s,1}(:,:,o);
% %         [maxval,maxidx]=max(rf(:));
% %         [fov_y,fov_x]=ind2sub(size(rf),maxidx);
% %         figure, imagesc(get_ior_gaussian(fov_x, fov_y, 1, s,1,wlev, 8, size(w{s,1}(:,:,o),1), size(w{s,1}(:,:,o),2), rad2deg(36)));
% %         title(['IOR: s=' num2str(s) ',o=' num2str(o)]);
%    end
% end
end




