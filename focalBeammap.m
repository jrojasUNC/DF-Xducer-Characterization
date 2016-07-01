clear all

[filename, pathname] = uigetfile( ...       % get path of files desired to open
{'*.tdms'},'Select tdms file to analyze','Multiselect','On');


if iscell(filename)
    numFiles=size(filename,2);
else
    numFiles=1;
end

for file=1:numFiles
   
   if numFiles==1
        Data=readPDAnew_2011_function(pathname,filename);
   else
       Data=readPDAnew_2011_function(pathname,filename{file}); 
   end
   
    
   
   beamMap=abs(Data.voltageData);
%    beamMap=beamMap/max(max(beamMap));
%    figure; imagesc(Data.xRange,Data.zRange,beamMap);
%  
end

[X,Y]=meshgrid(Data.xRange,Data.zRange);

% x=Data.xRange(1):.01:Data.xRange(end);
% y=Data.zRange(1):.01:Data.zRange(end);
x=-1.5:.01:1.5;
y=-1.5:.01:1.5;
[Xq,Yq]=meshgrid(x,y);

beamMap=interp2(X,Y,beamMap,Xq,Yq,'spline',min(min(beamMap)));

figure; imagesc(x,y,beamMap);
xlabel('Lateral distance (mm)');
ylabel('Elevational distance (mm)');




