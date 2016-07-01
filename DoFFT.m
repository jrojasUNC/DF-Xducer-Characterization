function [f,meanYFFT]=DoFFT(y,Fs,size,type)

% Fs= sampling frequency (HZ)
% y=signal
% type= normalize (1) or don't normalize
% size size of file 1D (1), 2D (2), for 2 D it will do fft on columns and
% average them

L=length(y);
T=1/Fs;
t = (0:L-1)*T;                % Time vector

NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);


if isvector(Y)

    YFFT=2*abs(Y(1:NFFT/2+1));

else
    YFFT=2*abs(Y(1:NFFT/2+1,:));
end  
    

switch size
    case 1
        meanYFFT=YFFT;
    case 2
        meanYFFT=mean(YFFT,2);
end

if type
    
    meanYFFT=20*log10(meanYFFT/max(meanYFFT));
    
    % Plot single-sided amplitude spectrum.
    figure; plot(f,meanYFFT) 
    title('Single-Sided Amplitude Spectrum of y(t)')
    xlabel('Frequency (Hz)')
    ylabel('Normalized Amplitude (dB)')
else
    
    % Plot single-sided amplitude spectrum.
    figure; plot(f,meanYFFT) 
    title('Single-Sided Amplitude Spectrum of y(t)')
    xlabel('Frequency (Hz)')
    ylabel('Amplitude')
        
end



end