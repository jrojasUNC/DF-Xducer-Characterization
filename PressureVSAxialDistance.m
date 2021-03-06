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
   
%    figure; imagesc(Data.zRange,Data.yRange,Data.voltageData);
   
   PNP=abs(min(Data.voltageData,[],2));
   
 
end

PNP=(PNP-min(PNP));
PNP=PNP/max(PNP);

z=-5:.1:5;
PNP=interp1(Data.yRange,PNP,z);


 figure; plot(z,PNP);

% diffoc=(93.2291-88.3115);            % differece between foci axial distance, in relation to LF focus
diffoc=(92.0375-86.9376);
z_HF=z_LF+diffoc;

 figure; plot(z_LF+15,PNP_LF,z_HF+15,PNP_HF);
 title('Axial pressure')
 xlabel('distance from Low-Frequency Focus (mm)');
 ylabel('Normalized Pressure');
 legend('Low-Frequency Element','High-Frequency Element');


