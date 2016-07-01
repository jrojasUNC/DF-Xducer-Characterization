clear all

type='HF';
switch type
case 'LF'
    
        load('LF_focus.mat')
        load('LF_focus_minus1mm.mat')
        load('LF_focus_plus1mm.mat')

        tempBeamMap(:,:,1)=LF_focus;
        tempBeamMap(:,:,2)=LF_focus_minus1mm;
        tempBeamMap(:,:,3)=LF_focus_plus1mm;
    
case 'HF'
        load('HF_focus.mat')
        load('HF_focus_minus1mm.mat')
        load('HF_focus_plus1mm.mat')

        tempBeamMap(:,:,2)=HF_focus;
        tempBeamMap(:,:,1)=HF_focus_minus1mm;
        tempBeamMap(:,:,3)=HF_focus_plus1mm;
        
end

tempBeamMap=tempBeamMap/max(max(max(tempBeamMap)));

[X,Y,Z]=meshgrid(x,y,[-1 0 1]);
z=-1:.1:1;
[Xq,Yq,Zq]=meshgrid(x,y,z);

beamMap3D_HF=interp3(X,Y,Z,tempBeamMap,Xq,Yq,Zq);

%%
frametoplot=round(length(x)/2);


% HF_temp=zeros(301,301);
% HF_temp(110:190,110:190)=beamMap3D_HF(:,:,11);
% figure; imagesc(x,y,HF_temp'); colormap gray
% xlabel('Elevational Distance (mm)');
% ylabel('Axial Distance (mm)');
% title('XY Beammap of High-Frequency Element')


figure; imagesc(x*1000,y*1000,squeeze(beamMap3D_HF(:,:,11))'); colormap gray
xlabel('Elevational Distance (um)');
ylabel('Axial Distance (um)');
title('XY Beammap of High-Frequency Element')

figure; imagesc(x,z,squeeze(beamMap3D_HF(frametoplot,:,:))');
xlabel('Elevational Distance (mm)');
ylabel('Axial Distance (mm)');
title('ZY Beammap of High-Frequency Element')

figure; imagesc(x,z,squeeze(beamMap3D_HF(frametoplot,:,:))');
xlabel('Lateral Distance (mm)');
ylabel('Axial Distance (mm)');
title('XZ Beammap of High-Frequency Element')

% figure; contour(x,z,squeeze(beamMap3D_HF(:,frametoplot,:))',[.6 .6]);
% xlabel('Lateral Distance (mm)');
% ylabel('Lateral Distance (mm)');
% title('XZ -6dB contour')

%%
offset=9;

load('HF_beamMap3D.mat')
BMdB=-20*ones(301,301);
temp=20*log10(squeeze(beamMap3D_HF(:,:,11))');
BMdB(100:200,100:200)=temp;
% BMdB(110:190,110:190)=temp;
x=-1.5:.01:1.5;
y=-1.5:.01:1.5;
figure; image(x*1000,y*1000,(256/offset)*(BMdB+ offset)); colormap(gray(256));
axis([-1000 1000 -1000 1000]);
xlabel('Elevational Distance (um)');
ylabel('Axial Distance (um)');
title('XY Beammap of High-Frequency Element')

load('LF_beamMap3D.mat')
BMdB=20*log10(squeeze(beamMap3D_HF(:,:,11))');
figure; image(x*1000,y*1000,(256/offset)*(BMdB+ offset)); colormap(gray(256));
axis([-1000 1000 -1000 1000]);
xlabel('Elevational Distance (um)');
ylabel('Axial Distance (um)');
title('XY Beammap of Low-Frequency Element')


BMdB=20*log10(squeeze(beamMap3D_HF(:,:,11))');

hold on
contour(x*1000,y*1000,BMdB,[-3 -3],'r','LineWidth',2);
contour(x*1000,y*1000,BMdB,[-6 -6],'g','LineWidth',2);
contour(x*1000,y*1000,BMdB,[-9 -9],'c','LineWidth',2);
contour(x*1000,y*1000,BMdB,[-12 -12],'y','LineWidth',2);
hold off
legend('-3dB','-6dB','-9dB','-12dB')
title('');

figure; contour(x,y,squeeze(beamMap3D_HF(:,:,10)),[.5 .9],'b');
% load('HF_beamMap3D.mat') 
% hold on
% contour(x,y,squeeze(beamMap3D_HF(:,:,10)),[.6 .6],'r');
% hold off
% legend('Low-Frequency Element','High-Frequency Element');
% xlabel('Lateral Distance (mm)');
% ylabel('Elevational Distance (mm)');
% title('-6dB Contours')

