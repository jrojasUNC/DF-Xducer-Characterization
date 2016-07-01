% Steven Feingold
% updated 7/23/2012
% Function reads binary data written by A-mode, M-mode, Calibrate
% Transducers, Map XY and Map XZ LabView programs.  Newest version is more
% readable with fewer redundant lines of code

% updated 8/22/12 by KHM
% updated the hydrophone calibrations to be of relative address based on how
% the user has mapped the Drobo folder. Currently resides on Steve's
% computer which is daytonlab7
% Updated to include treatment for type 'v' (YZ) scans.

% updated 10/16/12 by KHM
% type 'n' (m-mode file TDMS) was out of date and giving poop. Added
% approriate data reshaping for type 'n' so it interprets data correctly.

% updated 2-6-13 by SGF
% Fix bug in FFT pressure calibrations

% updated 2-12-13 by SGF
% add option to save excel file for files saved by calibrate transducers

% updated 1/17/14 khm
% redid it baby, calls tdms_read. Transition to labview 2011 caused
% numerous errors in hardcode reads from the tdms data. Adapting to new
% code requires adaptive changes of memory location of stored datasets.
% Designed to be backwards compatible. Removed Excel Script and Save Image
% type:
%       b       A mode (old = check, new = check)
%       d       Calibration xxxxxx
%       e       Calibration waveforms file xxxxx
%       f       Automated Multipressure Acquisition (AMA) xxxxx
%       n       M-mode xxxx
%       v       Beammap - YZ (old = check)
%       w       Beammap - xxxx
%       x       Beammap - zx TODO: Fix ZX postive waveform saves so it does
%       xxxx
%       NOT save it as type 'v' but saves it correctly as a type 'x'

curdir = cd;
drobocomputer = 'daytonlab7';
drobopath = strcat('\\ad.unc.edu\med\bme\Groups\DaytonLab\public\Transducers',...
    ' and Hydrophones\Hydrophones\Matlab versions\');

MACdrobopath = ['/Volumes/public/Transducers',...
    ' and Hydrophones/Hydrophones/Matlab versions/'];
%% check to see if hydrophone directory exists where we expect it
try
    cd(drobopath);
    cd(curdir);
catch er
    try
        drobopath = MACdrobopath;
        cd(drobopath);
        cd(curdir);
    catch me
        drobopath=uigetdir('','Select Hydrophone directory');
    end
end

info.drobopath = drobopath;

%% ****Structure to decode LabVIEW data on hydrophone, amplifier type****

infoStruct(1).hydrophoneNames = 'None';
infoStruct(2).hydrophoneNames = 'HNC-0200 1087';
infoStruct(3).hydrophoneNames = 'HNA-0400 1050';
infoStruct(4).hydrophoneNames = 'PA-1004';

infoStruct(1).preAmpNames = 'None';
infoStruct(2).preAmpNames = 'AH 1100';
infoStruct(3).preAmpNames = 'DCPS076';

infoStruct(1).preAmpAttenNames = 'None';
infoStruct(2).preAmpAttenNames = 'ATH 2000';

infoStruct(1).amplifierNames = 'None';
infoStruct(2).amplifierNames = 'ENI 3200 #1';
infoStruct(3).amplifierNames = 'ENI 3200 #2';
infoStruct(4).amplifierNames = 'ENI A-500';
infoStruct(5).amplifierNames = 'O/P NDT';
infoStruct(6).amplifierNames = 'ENI 3100LA';
infoStruct(7).amplifierNames = 'ENI AP400B';
infoStruct(8).amplifierNames = 'RITEC';
infoStruct(9).amplifierNames = 'Panametric 5077PR';

infoStruct(1).ampAttenuatorNames = 'None';
infoStruct(2).ampAttenuatorNames = '3db';
infoStruct(3).ampAttenuatorNames = '6db';
infoStruct(4).ampAttenuatorNames = '10db';
infoStruct(5).ampAttenuatorNames = '20db';

infoStruct(1).hydrophoneCalibrations = strcat(drobopath,'1087_with_preamp.mat');
infoStruct(2).hydrophoneCalibrations = strcat(drobopath,'1087_with_preamp_and_attenuator.mat');
infoStruct(3).hydrophoneCalibrations = strcat(drobopath,'1050_with_preamp.mat');
infoStruct(4).hydrophoneCalibrations = strcat(drobopath,'1050_with_preamp_and_attenuator.mat');
infoStruct(5).hydrophoneCalibrations = strcat(drobopath,'precision_Acoustics.mat');

%% Load file
[info.filename, info.pathname] = uigetfile( ...  % get path of file desired to open
    {'*.tdms',  'Labview data files '; ...
    '*.*',  'All Files (*.*)'},'Select LabVIEW file from ADC');

if info.filename == 0       % if user cancelled when looking for files
    clear infoStruct info drobocomputer drobopath
    return
    % exit the script
end

info.wholeFilename = fullfile(info.pathname, info.filename);
cd(info.pathname)           % Set new default search directory

[output,meta] = TDMS_readTDMSFile(info.wholeFilename);
nGroups = length(output.groupIndices);
nChannels = length(output.chanIndices);
nObjects = length(output.objectPathsOrig);

fid = fopen(info.filename); % <TODO> GET rid of all fid sequences.
file = fscanf(fid,'%c');    % load file into memory as string

%% Determine which LabVIEW program saved the file

% determine the type of scan
% determine comment
% identify header group, assume rest are data groups
dataGroupIndex = zeros(1,nGroups-1);
stepperindex = 0;

for ii = 1:nGroups
    % determine which group has the jkpn test string
    full = output.groupNames{ii};
    loc=strfind(full,'jkpn');
    if ~isempty(loc)
        headerGroupIndex = output.groupIndices(ii); % record data index
        info.type = full(loc(1)+4);
        info.comment = full((loc(1)+5):(loc(2)-1));
    else
        stepperindex = stepperindex+1;
        dataGroupIndex(stepperindex) = output.groupIndices(ii);
    end
end
if info.type == 'a' || info.type =='m' || info.type =='z' || info.type =='y'
    disp('Out of date LabVIEW program, use original readPDA.m')
end

%% Categorize Header Data

% get header channel
headerChannelIndex = headerGroupIndex + 1; % the channel index is listed right after the header group
headerData = output.data{headerChannelIndex};

dataStart = strfind(file,'wf_xunit_string');        % find start of data
% fseek(fid,dataStart(1)+23,-1);                      % place file pointer at start of data
% headerData = fread(fid, 9, 'double');               % read first line of data (header info)

info.hydrophone = infoStruct(headerData(1)+1).hydrophoneNames;      % catagorize header info
info.preAmp = infoStruct(headerData(2)+1).preAmpNames;
info.preAmpAtten = infoStruct(headerData(3)+1).preAmpAttenNames;
info.amplifier = infoStruct(headerData(4)+1).amplifierNames;
info.ampAtten = infoStruct(headerData(5)+1).ampAttenuatorNames;
data.delay = headerData(6);
data.maxFrequency = headerData(7);
horizontalSize = headerData(8);                            % retrieve header info from data
verticalSize = headerData(9);
headerLength = 9;

if info.type == 'w'       % beammaps require extra data to be loaded
    data.xRange = headerData((headerLength+1):(headerLength+horizontalSize));
    data.yRange = headerData((end-verticalSize+1):end);
    %     data.xRange = flipud( fread(fid, horizontalSize, 'double') );
    %     data.yRange = fread(fid, verticalSize, 'double');
elseif info.type == 'x'
    data.xRange = headerData((headerLength+1):(headerLength+horizontalSize));
    data.zRange = headerData((end-verticalSize+1):end);
    %     data.xRange = flipud(fread(fid, horizontalSize, 'double'));
    %     data.zRange = fread(fid, verticalSize, 'double');
elseif info.type == 'v'
    data.zRange = headerData((headerLength+1):(headerLength+horizontalSize));
    data.yRange = headerData((end-verticalSize+1):end);
elseif info.type == 'd'     % calibration file requires extra data loaded
    data.voltages = headerData((headerLength+1):(headerLength+horizontalSize));
    data.frequencies = headerData((end-verticalSize+1):end);
    %     data.voltages = fread(fid, horizontalSize, 'double');
    %     data.frequencies = fread(fid, verticalSize, 'double');
elseif info.type == 'e'     % calibration waveform file requires extra data loaded
    data.voltages = headerData((headerLength+1):(headerLength+horizontalSize));
    data.frequencies = headerData((end-verticalSize+1):end);
    %     data.voltages = fread(fid, horizontalSize, 'double');
    %     data.frequencies = fread(fid, verticalSize, 'double');
    zSize = headerData(7);
    data = rmfield(data,'maxFrequency');
elseif info.type == 'f'                 % AMA requires extra data loaded
    data.voltages = headerData((headerLength+1):(headerLength+horizontalSize));
    data.presOfVoltages = headerData((end-horizontalSize+1):end);
    %     data.voltages = fread(fid, horizontalSize, 'double');   %input voltages supplied
    %     data.presOfVoltages = fread(fid, horizontalSize, 'double');
    zSize = headerData(7);
    data = rmfield(data,'maxFrequency');
end

%% Load in voltage data

if info.type == 'b'
    % get Data channel, assumes only 1 present per data (consitent with both
    % 2010 and 2011 saves from labview via express tdms vi.
    dataChannelIndex = dataGroupIndex + 1;
    lineOfData = output.data{dataChannelIndex};
    
    data.voltageData = reshape(lineOfData,horizontalSize,verticalSize)';
    
    %     fseek(fid,dataStart(2)+23,-1);                      % place file pointer at start of first run
    %     run1 = fread(fid, horizontalSize, 'double');        % load first a-mode line
    %     allRuns = zeros(length(run1),verticalSize);    % Pre-allocated space before looping
    %     allRuns(:,1) = run1;
    %     offset = 3*8+4;
    %     fseek(fid,105-offset,0);
    %     for i = 2:verticalSize                        % read additional lines
    %
    %         fseek(fid,offset,0);
    %         runi = fread(fid, 1*horizontalSize, 'double');
    %         figure(1);plot(runi);ylim([-0.5 0.5]);
    % %         allRuns(:,i) = runi;
    %
    %         % append lines together
    %     end
    %
    %     data.voltageData = allRuns';                         % transpose data
    
    %***************************************************************************************
elseif info.type == 'x' || info.type == 'w' || info.type == 'd' || info.type == 'v'
    dataChannelIndex = dataGroupIndex + 1;
    raw_data = output.data{dataChannelIndex};
    
    %     fseek(fid,dataStart(2)+23,-1);                                                  % place file pointer at start of first run
    %     raw_data = fread(fid, horizontalSize*verticalSize, 'double');                   % save scanned data in a column vector
    if info.type == 'd'
        dataU = reshape(raw_data, horizontalSize, verticalSize);                    % multi frequency calibration files need to be read in different order
    else
        dataU = reshape(raw_data, verticalSize, horizontalSize);                    % reshape the data to match the scanning pattern
    end
    data.voltageData = dataU';
    
    if info.type == 'v'
        data.voltageData = fliplr(data.voltageData');
    end
    
elseif info.type == 'e'
    
    fseek(fid,dataStart(2)+23,-1);                                                  % place file pointer at start of first run
    raw_data = fread(fid, horizontalSize*verticalSize*zSize, 'double');             % save scanned data in a column vector
    data.voltageData = reshape(raw_data, zSize, horizontalSize, verticalSize);      % reshape the data to match the scanning pattern
elseif info.type == 'f'
    
    fseek(fid,dataStart(2)+23,-1);                                                  % place file pointer at start of first run
    raw_data = fread(fid, horizontalSize*verticalSize*zSize, 'double');             % save scanned data in a column vector
    data.voltageData = reshape(raw_data, zSize, verticalSize,horizontalSize);      % reshape the data to match the scanning pattern
    data.voltageData = permute(data.voltageData,[2 1 3]); %re order so its (line number, time, input voltage/pressure levels)
elseif info.type == 'n'
    raw_data = headerData((headerLength+1):end);   % m-mode data located in "header" location.
    dataU = reshape(raw_data, horizontalSize, verticalSize);                        % reshape the data to match the scanning pattern
    data.voltageData = dataU';
end

%% Create timeScale vector

if info.type == 'n' || info.type == 'b' %
    data.timeScale = (data.delay:.01:data.delay + size(data.voltageData,2)/100);   % create time axis for plotting
    data.timeScale(end) = [];
    %TODO: Modify Labview Calibration code such that columns are fast time in
    % acquired waveforms. Additionally, change delay scale to be in 100*
    % samples instead of 1*samples?
elseif info.type == 'e'
    data.timeScale = (data.delay*1e-2:.01:data.delay*1e-2 + size(data.voltageData,1)/100);   % create time axis for plotting
    data.timeScale(end) = [];
    % TODO: modify labview code for type 'f' so it saves delay as 1/100 it's
    % size plz
elseif info.type == 'f'
    data.timeScale = (data.delay*1e-2:.01:data.delay*1e-2 + zSize/100);   % create time axis for plotting
    data.timeScale(end) = [];
end
%% Determine if a calibration file exists for calculating pressure

if strcmp(info.hydrophone, 'HNC-0200 1087') && strcmp(info.preAmp, 'AH 1100') && strcmp(info.preAmpAtten,'None')
    info.calibrationFile = infoStruct(1).hydrophoneCalibrations;
elseif strcmp(info.hydrophone, 'HNC-0200 1087') && strcmp(info.preAmp, 'AH 1100') && strcmp(info.preAmpAtten,'ATH 2000')
    info.calibrationFile = infoStruct(2).hydrophoneCalibrations;
elseif strcmp(info.hydrophone, 'HNA-0400 1050') && strcmp(info.preAmp, 'AH 1100') && strcmp(info.preAmpAtten,'None')
    info.calibrationFile = infoStruct(3).hydrophoneCalibrations;
elseif strcmp(info.hydrophone, 'HNA-0400 1050') && strcmp(info.preAmp, 'AH 1100') && strcmp(info.preAmpAtten,'ATH 2000')
    info.calibrationFile = infoStruct(4).hydrophoneCalibrations;
elseif strcmp(info.hydrophone, 'PA-1004') && strcmp(info.preAmp, 'DCPS076') && strcmp(info.preAmpAtten,'None')
    info.calibrationFile = infoStruct(5).hydrophoneCalibrations;
else
    info.calibrationFile = -1;        %cannot convert voltage data to pressure data
end

if (info.type == 'w' || info.type == 'x' || info.type == 'v') && data.maxFrequency == -1
    info.calibrationFile = -1;              % we have the calibration file, but don't know the frequency!
end

%% If there a pressure calibration and a waveform file, create appropriate frequency version of calibration

if info.calibrationFile ~= -1               % if a calibration file exists, then
    
    load(info.calibrationFile);             % load proper calibration file
    data.hydroCals = hydro_cals;            % store in data function
    
    if info.type == 'b' || info.type == 'n' || info.type == 'e' % if we have a full waveform, and not just a peak value
        pressSens = zeros(1001,1);                          % convert hyrdophone calibration fft spectrum reaching to nyquist frequency of PDA14 (50 MHz)
        pressSens(6:401,1) = 1./data.hydroCals(:,3);        % to be multipled by fft of data, first calibrated frequency is .25 MHz, so goes in 6th place
        Fs = 1e8;                                           % sampling frequency of PDA 14
        f = 0:.05e6:50e6;                                   % sampling frequencies of hydrophone calibration up to Nyquist (50 MHz)
        %TODO: Fix type 'e' based on interping frequency of hydrocals (col 1)
        if info.type == 'e'
            
            fdata = fft(data.voltageData,[],1);
            N = size(fdata,1);
            f_vec = (0:(N-1))/N*Fs;
            sen_v_per_pa = interp1(data.hydroCals(:,1)*1e6,...
                data.hydroCals(:,3),f_vec,'spline',Inf);
            pressSens = 1./(sen_v_per_pa);
            clear sen_v_per_pa file raw_data hydro_cals f %clear variables to empty workspace memory for large memory operation coming next
            fcorr = fdata.*repmat(...
                pressSens',[1 size(fdata,2) size(fdata,3)]);    % correct data by hyrdophone calibration
            cor = real(ifft(fcorr,[],1));
            
        else
            NFFT = 2^nextpow2(size(data.voltageData,2));        % Next power of 2 from length of voltageData for better FFT function
            fdata = fft(data.voltageData,NFFT,2);               % take FFT of voltage data
            freqOfFFT = Fs/2*linspace(0,1,NFFT/2+1);            % the frequencies present in FFT data
            
            pressSensInterp = interp1(f,pressSens,freqOfFFT);   % interpolate the hydrophone calibration to the new FFT sampling
            sens2 = [pressSensInterp(1:end-1) fliplr(pressSensInterp)];     % generate negative frequencies in hydrophone calibration
            sens2(end) = [];                                    % 0 MHz (DC) sensitivity should only appear once
            fcorr = fdata.*repmat(...                           % multiply fft data by hydrophone sensitiviy
                sens2,size(fdata,1),1);
            
            cor = real(ifft(fcorr,NFFT,2));                     % convert corrected frequency data back into the time domain
            cor = cor(:,1:size(data.voltageData,2));            % cut off the part appended by introducing next power of two
            
        end
        
        if size(data.voltageData,2)<2000 && ~strcmp(info.type,'e')
            data.pressureData = cor(:,1:size(data.voltageData,2));           % remove extraneous portion of signal
        else
            data.pressureData = cor;
        end
        
        
    elseif info.type == 'd'                     % we have a calibration file
        indices = data.frequencies.*20-4;    % create list of freq index for hydrophone calibration file
        hydro = data.hydroCals(indices,3);   % index into calibration file to get
        data.pressureData = data.voltageData./repmat(hydro,1,size(data.voltageData,2));       % apply calibration to data
        
    elseif info.type == 'w' || info.type == 'x' || info.type == 'v'
        data.pressureData = data.voltageData/data.hydroCals(round(20*data.maxFrequency-4),3);  % calculate which hydrocal to use and apply it
        
        if info.type == 'w' || info.type == 'x'
            data.pressureData = fliplr((data.pressureData)');
        end
        
    end
end

%% Display images according to type

if info.type == 'b'
    if size(data.voltageData,1) == 1                                % Display data if only 1 run recorded
        plot(data.timeScale,data.voltageData);
        xlabel('Time (us)'); ylabel('Voltage')
        if info.calibrationFile ~= -1                   % plot calibrated pressure data if it exists
            plot(data.timeScale,data.pressureData);
            xlabel('Time (us)'); ylabel('Pressure')
            
        end
        title(info.filename);
        
        
    else                                                % Display data if multiple runs recorded
        imagesc(data.timeScale, 1:size(data.voltageData,1), data.voltageData);
        if info.calibrationFile ~= -1                  % Plot calibrated pressure data if it exists
            imagesc(data.timeScale, 1:size(data.voltageData,1), data.pressureData);
        end
        xlabel('time (us)'); ylabel('Line Number')
        title(info.filename);
    end
    
    colormap(jet)
    
elseif info.type == 'n'
    
    if info.calibrationFile ~= -1                                      % if data is calibrated, display that instead
        imagesc(data.timeScale, 1:size(data.voltageData,1), data.pressureData);
    else
        imagesc(data.timeScale, 1:size(data.voltageData,1), data.voltageData);
    end
    
    colorbar; colormap(gray);
    xlabel('time (us)'); ylabel('Line Number')
    title(info.filename);
    
    
elseif info.type == 'x'
    if info.calibrationFile ~= -1
        imagesc(data.xRange,data.zRange,data.pressureData)                 % Display the data
    else
        imagesc(data.xRange,data.zRange,data.voltageData)                 % Display the data
    end
    xlabel('X (mm)'); ylabel('Z (mm)')
    title(info.filename);
    axis equal; colorbar
    set(gca,'XDir','reverse');
    
elseif info.type == 'w'
    if info.calibrationFile ~= -1
        imagesc( data.xRange, data.yRange, data.pressureData )              % Display the data
    else
        imagesc( data.xRange, data.yRange, data.voltageData )
    end
    xlabel('X (mm)'); ylabel('Y (mm)')
    title(info.filename);
    axis equal; colorbar
    set(gca,'XDir','reverse');
    
elseif info.type == 'v'
    if info.calibrationFile ~= -1
        imagesc(data.zRange,data.yRange,data.pressureData)                 % Display the data
    else
        imagesc(data.zRange,data.yRange, data.voltageData)
    end
    xlabel('Z (mm)'); ylabel('Y (mm)')
    title(info.filename);
    axis equal; colorbar
    
    
elseif info.type == 'd'
    if size(data.frequencies,1) == 1
        if info.calibrationFile ~= -1           % if there is a calibration file...
            plot(data.voltages, data.pressureData)
            xlabel('Arb voltages'),ylabel('Pressure (Pa)');
        else
            plot(data.voltages, data.voltageData)
            xlabel('Arb voltages'); ylabel('hydrophone voltages')
        end
        title(info.filename)
        
        
    else
        if info.calibrationFile ~= -1
            imagesc(data.voltages,data.frequencies,data.pressureData)
        else
            imagesc(data.voltages,data.frequencies,data.voltageData)
        end
        xlabel('Voltage'); ylabel('Frequency')
        title(info.filename);
        colorbar
        
        
    end
elseif info.type == 'e'
    square_size = ceil(sqrt(size(data.voltageData,2)));
    if info.calibrationFile ~= -1
        for ii = 1:size(data.voltageData,2)
            subplot(square_size,square_size,ii)
            plot(data.timeScale,1e-3*squeeze(data.pressureData(:,ii,:)));
            xlim([data.timeScale(1) data.timeScale(2000)]); %window to 20us
            title(['V_i_n = ' num2str(data.voltages(ii))]);
            ylim([1e-3*min(data.pressureData(:)) 1e-3*max(data.pressureData(:))]);
            xlabel('Time, \mus');
            ylabel('Pressure, kPa');
        end
        legend(num2str(data.frequencies));
        %         imagesc(data.voltages,data.frequencies,data.pressureData')
    else
        for ii = 1:size(data.voltageData,2)
            subplot(square_size,square_size,ii)
            plot(data.timeScale,squeeze(data.voltageData(:,ii,:)));
            xlim([data.timeScale(1) data.timeScale(2000)]); %window to 20us
            title(['V_i_n = ' num2str(data.voltages(ii))]);
            ylim([min(data.voltageData(:)) max(data.voltageData(:))]);
            xlabel('Time, \mus');
            ylabel('Voltage, V');
        end
        legend(num2str(data.frequencies));
        %         imagesc(data.voltages,data.frequencies,data.voltageData')
    end
    
elseif info.type == 'f'
    if verticalSize == 1 %if there is only one line of data recorded at each combo of freq and vin...
        imagesc(data.timeScale,data.presOfVoltages,data.voltageData');
        xlabel('Time, \mus');
        ylabel('Applied Pressure, kPa');
        title('Received Voltages as a function of applied pressures');
        if info.calibrationFile ~= 1
            imagesc(data.timeScale,data.presOfVoltages,data.pressureData);
            title('Recieved Pressure (Pa) as a function of applied pressures');
        end
        colormap gray;
    else %if there are multiple lines of data collected at each combo of freq and vin...
        square_size = ceil(sqrt(length(data.voltages)));
        for ii = 1:length(data.voltages)
            subplot(square_size,square_size,ii)
            m_to_plot = squeeze(data.voltageData(:,:,ii));
            imagesc(data.timeScale,[],m_to_plot);
            %             TODO: Either remove pressureData field from data structure or
            %             convert to pressure values using appropriate hydrocal data.
            %             if info.calibrationFile ~= -1
            %                 imagesc(data.timeScale,[],squeeze(data.pressureData(:,:,ii)));
            %             end
            title(['P_i_n = ' num2str(data.presOfVoltages(ii)*1e-3) ' kPa']);
            xlabel('Time, \mus');
            ylabel('Line Number');
            colormap gray
        end
        
        
    end
    
end


%% Close open file, delete remaining extraneous variables

fclose(fid);
clear fid dataU raw_data dataStart horizontalSize verticalSize file sheetname Fs NFFT f freqOfFFT presSensInterp
clear headerData CommentLoc indices hydro_cals AddData allRuns cor fcorr sens2
clear fdata i pressSens run1 runi ans zSize drobocomputer drobopath MACdrobopath
clear fig_handle curdir hydro header1 header2 headerInfo
clear ii excelObj excelWorkbook fn freqCell numSheets pn sheetIdx sheetIdx2 temp title worksheets excelTitle
clear m_to_plot square_size dataChannelIndex dataGroupIndex full headerChannelIndex
clear nObjects meta output nGroups nChannels stepperindex loc infoStruct headerGroupIndex
clear headerLength lineOfData