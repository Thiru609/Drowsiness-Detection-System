function [higlighted_img,x] = Segment_fn(img1,img2)



%% Convert to B&W
img1BW = rgb2gray(img1);
img2BW = rgb2gray(img2);

% %% Display B&W images
% figure
% imshow(img1BW)
% figure
% imshow(img2BW)

%% Subtract
imgDiff = abs(img1BW - img2BW);
% figure
% imshow(imgDiff)

%% Find Max and Min location Differences
maxDiff = max(max(imgDiff));
[iRow, iCol] = find(imgDiff == maxDiff);
[m,n] = size(imgDiff);

% imshow(imgDiff);
%  hold on
% plot(iCol, iRow, 'r*')

%% Determine threshold and length
%imtool(imgDiff);

%% Threshold Image 
imgThresh = imgDiff > 8;

% figure
% imshow(imgThresh)
% hold on
% plot(iCol, iRow, 'r*')
% hold off

%% Fill in regions
 imgFill = bwareaopen(imgThresh, 50);
%  figure 
%  imshow(imgFill)
 
 %% Overlay onto original image
 
 imgBoth = imoverlay(img2, imgFill, [1,0,0]);
%  figure
%  imshow(imgBoth)
higlighted_img = imgBoth;
 
 %% Only care about difference > 700
 
 imgStats = regionprops(imgFill, 'MajorAxisLength');
 imgLen = [imgStats.MajorAxisLength];
 idx = imgLen > 700;
 imgSFinal = imgStats(idx);

 
 

  % Significant Changes
 if isempty(imgSFinal)
     x=1;
     
 else
     x=-1;
 end
 
 
 

