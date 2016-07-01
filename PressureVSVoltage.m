clear all

[filename, pathname] = uigetfile( ...       % get path of files desired to open
{'*.tdms'},'Select tdms file to analyze','Multiselect','On');

type='LF';          % which type of data is this, from High frequency element or Low frequency element

if iscell(filename)
    numFiles=size(filename,2);
else
    numFiles=1;
end

switch type
    case 'LF'
        Voltages_preAmp=[60 90 120 150 180];           % pk-to-pkvoltages on arb in mV
        amp=55;                                        % gain of amplifier used in dB
        Voltages=10^(55/20)*Voltages_preAmp/1000;      % voltage going to the transducer after amplification in V
    case 'HF'
        Voltages_postAtt=[4.24 6.5 6.8];               % PNP of voltages from pulser at 1,2, and 4 uj measured on an oscilloscope after attenuating
        att=21.5;                                      % attenuation of pulser output for oscilloscope measurement
        Voltages=10^(att/20)*Voltages_postAtt;                 % voltage going to the transducer
end

for file=1:numFiles
   
   if numFiles==1
        Data=readPDAnew_2011_function(pathname,filename);
   else
       Data=readPDAnew_2011_function(pathname,filename{file}); 
   end
   
   PNP(file)=max(mean(Data.pressureData))/1e6;          % peak negative pressure in MPa
  
end

switch type
    case 'LF'
        figure; plot(Voltages,PNP(6:10),Voltages,PNP(1:5));
        title('Low-Frequency Element');
        xlabel('Voltage (V)');
        ylabel('PNP (MPa)');
        legend('Low-Frequency Focus','High-Frequency Focus');
    case 'HF'
        figure; plot(Voltages,PNP);
        title('High-Frequency Element');
        xlabel('Voltage (V)');
        ylabel('PNP (MPa)');
end


