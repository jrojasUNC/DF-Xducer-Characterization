clear all

[filename, pathname] = uigetfile( ...       % get path of files desired to open
{'*.tdms'},'Select tdms file to analyze','Multiselect','On');

type='HF';          % which type of data is this, from High frequency element or Low frequency element

if iscell(filename)
    numFiles=size(filename,2);
else
    numFiles=1;
end

fs=100e6;               % sampling frequency of the ADC card in Hz

for file=1:numFiles
   
   if numFiles==1
        Data=readPDAnew_2011_function(pathname,filename);
   else
       Data=readPDAnew_2011_function(pathname,filename{file}); 
   end
   
   
   temp=mean(Data.voltageData);          % voltage trace 
   temp2=zeros(1,800);
   temp2(round(400-length(temp)/2)+1:round(400+length(temp)/2))=temp;
   VoltTrace{file}=temp2;
   
   t{file}=Data.timeScale; 

   [f(:,file),Yfft(:,file)]=DoFFT(VoltTrace{file},fs,1,0);
end

temp=VoltTrace{1};
figure; plot(t{1},temp(251:550));
% figure; plot(t{1},VoltTrace{1});
title('Impulse Response of High-Frequency Element');
xlabel('time (usec)');
ylabel('Voltage');

figure; plot(t{2},VoltTrace{2});
title('Impulse Response of Low-Frequency Element');
xlabel('time (usec)');
ylabel('Voltage');

fnew=0:1000:50000000;
tempfft=20*log10(Yfft(:,1)/max(Yfft(10:end,1)));
fftnew=interp1(f(:,1)',tempfft,fnew);
figure; plot(fnew/1e6,fftnew);
axis([5 30 -20 0]);
title('Impulse Response of High-Frequency Element');
xlabel('Frequency (MHz)');
ylabel('Normalized Amplitude (dB)');


fnew=0:1000:50000000;
tempfft=20*log10(Yfft(:,2)/max(Yfft(10:end,2)));
fftnew=interp1(f(:,2)',tempfft,fnew);
figure; plot(fnew/1e6,fftnew);
axis([.5 15 -20 0]);
title('Impulse Response of Low-Frequency Element');
xlabel('Frequency (MHz)');
ylabel('Normalized Amplitude (dB)');
