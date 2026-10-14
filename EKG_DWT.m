function EKG_DWT()
% ==============================================================
% EKG_DWT.m
% DETEKSI P-Q-R-S-T ECG DENGAN DWT FROM SCRATCH
% ==============================================================
% Dataset contoh : PTB Diagnostic ECG Database
% File           : s0010_re.dat
% Sampling       : 1000 Hz
% Lead default   : Lead I
% Wavelet        : Daubechies db2 / D4 (4 tap)
%
% LPF & HPF ditulis MANUAL.
% DWT dibuat MANUAL (filtering + downsampling 2).
%
% Tidak memakai:
% dwt(), wavedec(), wfilters(), findpeaks()
%
% Hasil Detection = area/pulse P,Q,R,S,T, bukan marker titik.
% ==============================================================

%% =========================
% 1. WINDOW
% =========================
fig = uifigure('Name','Form1','Position',[80 45 1100 750]);

%% =========================
% 2. PANEL KIRI
% =========================
left = uipanel(fig,'Title','Process','Position',[5 5 180 740]);

uibutton(left,'Text','Data','Position',[10 680 65 25], ...
    'ButtonPushedFcn',@loadData);

% Kotak data seperti contoh
edN = uieditfield(left,'numeric','Position',[10 645 120 24], ...
    'Value',3000);
edFs = uieditfield(left,'numeric','Position',[10 610 120 24], ...
    'Value',1000);

uibutton(left,'Text','NData','Position',[10 575 65 25], ...
    'ButtonPushedFcn',@useAllData);

uibutton(left,'Text','Action','Position',[80 575 70 25], ...
    'ButtonPushedFcn',@runProcessing);

% Lead
uilabel(left,'Text','Lead','Position',[10 540 35 22]);
leadNames = {'I','II','III','aVR','aVL','aVF', ...
             'V1','V2','V3','V4','V5','V6'};
ddLead = uidropdown(left,'Items',leadNames,'Value','I', ...
    'Position',[50 540 100 24]);

% -------------------------
% T
% -------------------------
panelT = uipanel(left,'Title','T','Position',[5 310 170 215]);

T1 = addInput(panelT,'T1',160,70);   % Q window before R (ms)
T2 = addInput(panelT,'T2',125,90);   % S window after R (ms)
T3 = addInput(panelT,'T3',90,250);   % P search start before R (ms)
T4 = addInput(panelT,'T4',55,80);    % P search end before R (ms)
T5 = addInput(panelT,'T5',20,120);   % T search start after R (ms)

% -------------------------
% Delay
% -------------------------
panelD = uipanel(left,'Title','Delay','Position',[5 70 170 230]);

D1 = addInput(panelD,'Delay1',165,450); % T search end (ms)
D2 = addInput(panelD,'Delay2',130,400); % minimum RR (ms)
D3 = addInput(panelD,'Delay3',95,600);  % baseline window (ms)
D4 = addInput(panelD,'Delay4',60,120);  % refine R left (ms)
D5 = addInput(panelD,'Delay5',25,170);  % refine R right (ms)

lblStatus = uilabel(left,'Text','Belum ada data', ...
    'Position',[10 10 155 50],'WordWrap','on');

%% =========================
% 3. TAB GROUP
% =========================
tabs = uitabgroup(fig,'Position',[190 5 905 740]);

tabProcess   = uitab(tabs,'Title','Prosses');
tabMallat    = uitab(tabs,'Title','Mallat');
tabFilter    = uitab(tabs,'Title','Filter Bank');
tabZero      = uitab(tabs,'Title','Zero-cross');
tabGradient  = uitab(tabs,'Title','Gradient');
tabDetection = uitab(tabs,'Title','Detection');

tabs.SelectedTab = tabProcess;

%% =========================
% 4. TAB PROSSES
% =========================
axProcess = uiaxes(tabProcess,'Position',[55 110 800 520]);
title(axProcess,'Input','Color','b');
xlabel(axProcess,'Sampel');
ylabel(axProcess,'mV');
grid(axProcess,'on');

%% =========================
% 5. TAB MALLAT
% hanya tampilan
% =========================
uilabel(tabMallat,'Text','Mallat', ...
    'FontSize',18,'FontWeight','bold', ...
    'HorizontalAlignment','center', ...
    'Position',[300 330 300 40]);

%% =========================
% 6. FILTER BANK
% dibuat mirip gambar referensi
% =========================

% Input atas
axInput = uiaxes(tabFilter,'Position',[80 520 770 145]);
title(axInput,'Input','Color','b');
grid(axInput,'on');

% Tab g[n] / h[n]
ghTabs = uitabgroup(tabFilter,'Position',[35 285 400 205]);
tabG = uitab(ghTabs,'Title','g[n]');
tabH = uitab(ghTabs,'Title','h[n]');

axG = uiaxes(tabG,'Position',[35 30 330 140]);
title(axG,'g[n]','Color','b');

axH = uiaxes(tabH,'Position',[35 30 330 140]);
title(axH,'h[n]','Color','b');

% Tab FR g(x) / FR h(x)
frTabs = uitabgroup(tabFilter,'Position',[480 285 400 205]);
tabFRg = uitab(frTabs,'Title','FR g(x)');
tabFRh = uitab(frTabs,'Title','FR h(x)');

axFRg = uiaxes(tabFRg,'Position',[35 30 330 140]);
title(axFRg,'TChart','Color','b');

axFRh = uiaxes(tabFRh,'Position',[35 30 330 140]);
title(axFRh,'TChart','Color','b');

% D1-D5
axDetail = uiaxes(tabFilter,'Position',[35 35 400 210]);
title(axDetail,'TChart','Color','b');
grid(axDetail,'on');

% j tabs
jTabs = uitabgroup(tabFilter,'Position',[480 35 400 210]);
tabJ1 = uitab(jTabs,'Title','j1');
tabJ2 = uitab(jTabs,'Title','j2');
tabJ5 = uitab(jTabs,'Title','j5');
tabJ3 = uitab(jTabs,'Title','j3');
tabJ4 = uitab(jTabs,'Title','j4');

axJ1 = uiaxes(tabJ1,'Position',[35 30 330 140]);
axJ2 = uiaxes(tabJ2,'Position',[35 30 330 140]);
axJ5 = uiaxes(tabJ5,'Position',[35 30 330 140]);
axJ3 = uiaxes(tabJ3,'Position',[35 30 330 140]);
axJ4 = uiaxes(tabJ4,'Position',[35 30 330 140]);

%% =========================
% 7. ZERO/GRADIENT
% hanya tab agar GUI sama
% =========================
uilabel(tabZero,'Text','Zero-cross', ...
    'FontSize',18,'HorizontalAlignment','center', ...
    'Position',[300 330 300 40]);

uilabel(tabGradient,'Text','Gradient', ...
    'FontSize',18,'HorizontalAlignment','center', ...
    'Position',[300 330 300 40]);

%% =========================
% 8. DETECTION
% =========================
axDetect = uiaxes(tabDetection,'Position',[70 85 750 570]);
title(axDetect,'TChart','Color','b');
xlabel(axDetect,'Sampel');
ylabel(axDetect,'Amplitudo');
grid(axDetect,'on');

% Panel legend kanan
txtLegend = uitextarea(tabDetection, ...
    'Position',[835 420 60 180], ...
    'Editable','off', ...
    'Value',{'ECG';'P';'Q';'R';'S';'T'});

%% =========================
% 9. DATA INTERNAL
% =========================
raw = [];
fileName = '';

%% =============================================================
% LOAD DATA
% =============================================================
    function loadData(~,~)
        try
            [f,p] = uigetfile('*.dat','Pilih s0010_re.dat');
            if isequal(f,0), return; end

            fid = fopen(fullfile(p,f),'r','ieee-le');
            if fid==-1
                uialert(fig,'File tidak dapat dibuka.','Error');
                return;
            end

            % PTB s0010_re.dat = 12 lead, int16
            raw = fread(fid,[12 inf],'int16=>double');
            fclose(fid);

            if isempty(raw)
                uialert(fig,'Data kosong / format tidak sesuai.','Error');
                return;
            end

            fileName = f;

            % 3 detik agar tidak terlalu padat
            edN.Value = min(3000,size(raw,2));
            edFs.Value = 1000;

            n = round(edN.Value);
            ecg = raw(1,1:n)/2000;

            cla(axProcess);
            plot(axProcess,1:n,ecg,'Color',[0.23 0.35 0.60]);
            title(axProcess,'Input','Color','b');
            grid(axProcess,'on');

            cla(axInput);
            plot(axInput,1:n,ecg,'Color',[0.23 0.35 0.60]);
            title(axInput,'Input','Color','b');
            grid(axInput,'on');

            lblStatus.Text = sprintf('DATA OK\n%s\n%d sampel', ...
                f,size(raw,2));

            tabs.SelectedTab = tabProcess;
            drawnow;

        catch ME
            uialert(fig,ME.message,'Error Load');
        end
    end

%% =============================================================
% USE ALL DATA
% =============================================================
    function useAllData(~,~)
        if isempty(raw)
            uialert(fig,'Load data terlebih dahulu.','Info');
            return;
        end
        edN.Value = size(raw,2);
    end

%% =============================================================
% PROCESS
% =============================================================
    function runProcessing(~,~)
        try
            if isempty(raw)
                uialert(fig,'Klik Data terlebih dahulu.','Info');
                return;
            end

            fs = edFs.Value;
            N = min(round(edN.Value),size(raw,2));
            lead = find(strcmp(leadNames,ddLead.Value),1);

            %% A. ECG
            ecg = raw(lead,1:N)/2000;

            %% B. PREPROCESSING
            baseWin = max(3,round(D3.Value/1000*fs));
            baseline = movingAverage(ecg,baseWin);
            clean = ecg-baseline;
            clean = clean-mean(clean);

            %% C. LPF MANUAL - db2 / D4
            s2 = sqrt(2);
            s3 = sqrt(3);

            h = zeros(1,4);
            h(1) = (1+s3)/(4*s2);
            h(2) = (3+s3)/(4*s2);
            h(3) = (3-s3)/(4*s2);
            h(4) = (1-s3)/(4*s2);

            %% D. HPF MANUAL
            g = zeros(1,4);
            g(1) = (1-s3)/(4*s2);
            g(2) = -(3-s3)/(4*s2);
            g(3) = (3+s3)/(4*s2);
            g(4) = -(1+s3)/(4*s2);

            %% E. DWT MANUAL SAMPAI LEVEL 5
            A = cell(1,5);
            D = cell(1,5);

            x = clean;

            for level=1:5
                [A{level},D{level}] = dwtManual(x,h,g);
                x=A{level};
            end

            %% F. DETEKSI R DARI D5
            d5 = D{5};
            score = abs(d5);
            threshold = mean(score)+std(score);

            fsD5 = fs/32;
            minDist = max(1,round(D2.Value/1000*fsD5));
            cand = manualPeaks(score,threshold,minDist);

            R=[];

            for k=1:length(cand)
                rough=(cand(k)-1)*32+1;

                L=max(1,rough-round(D4.Value/1000*fs));
                U=min(N,rough+round(D5.Value/1000*fs));

                if U<=L, continue; end

                [~,loc]=max(clean(L:U));
                r=L+loc-1;

                if isempty(R) || r-R(end)>=round(D2.Value/1000*fs)
                    R(end+1)=r; %#ok<AGROW>
                end
            end

            %% G. DETEKSI Q,S,P,T
            P=nan(size(R));
            Q=nan(size(R));
            S=nan(size(R));
            T=nan(size(R));

            for k=1:length(R)
                r=R(k);

                % Q
                a=max(1,r-round(T1.Value/1000*fs));
                b=max(a,r-round(0.005*fs));
                if b>a
                    [~,loc]=min(clean(a:b));
                    Q(k)=a+loc-1;
                end

                % S
                a=min(N,r+round(0.005*fs));
                b=min(N,r+round(T2.Value/1000*fs));
                if b>a
                    [~,loc]=min(clean(a:b));
                    S(k)=a+loc-1;
                end

                % P
                a=max(1,r-round(T3.Value/1000*fs));
                b=max(a,r-round(T4.Value/1000*fs));
                if b>a
                    [~,loc]=max(clean(a:b));
                    P(k)=a+loc-1;
                end

                % T
                a=min(N,r+round(T5.Value/1000*fs));
                b=min(N,r+round(D1.Value/1000*fs));
                if b>a
                    [~,loc]=max(clean(a:b));
                    T(k)=a+loc-1;
                end
            end

            valid = ~isnan(P)&~isnan(Q)&~isnan(R)&~isnan(S)&~isnan(T);

            P=round(P(valid));
            Q=round(Q(valid));
            R=round(R(valid));
            S=round(S(valid));
            T=round(T(valid));

            %% H. AREA/PULSE PQRST
            gateP = pulseGate(P,N,round(0.025*fs),0.55);
            gateQ = pulseGate(Q,N,round(0.012*fs),0.70);
            gateR = pulseGate(R,N,round(0.012*fs),1.00);
            gateS = pulseGate(S,N,round(0.012*fs),0.85);
            gateT = pulseGate(T,N,round(0.030*fs),0.65);

            %% I. PROSSES
            cla(axProcess);
            plot(axProcess,1:N,clean,'Color',[0.23 0.35 0.60]);
            title(axProcess,['Input - Lead ',ddLead.Value],'Color','b');
            grid(axProcess,'on');

            %% J. FILTER BANK
            cla(axInput);
            plot(axInput,1:N,clean,'Color',[0.23 0.35 0.60]);
            title(axInput,'Input','Color','b');
            grid(axInput,'on');

            cla(axH);
            bar(axH,[-2 -1 0 1],h,0.65, ...
                'FaceColor',[0.30 0.42 0.65]);
            title(axH,'h[n]','Color','b');
            grid(axH,'on');

            cla(axG);
            bar(axG,[-2 -1 0 1],g,0.65, ...
                'FaceColor',[0.30 0.42 0.65]);
            title(axG,'g[n]','Color','b');
            grid(axG,'on');

            [w,Hmag]=manualFR(h,128);
            [~,Gmag]=manualFR(g,128);

            cla(axFRh);
            plot(axFRh,w,Hmag);
            title(axFRh,'TChart','Color','b');
            grid(axFRh,'on');

            cla(axFRg);
            plot(axFRg,w,Gmag);
            title(axFRg,'TChart','Color','b');
            grid(axFRg,'on');

            % D1-D5
            cla(axDetail);
            hold(axDetail,'on');

            colors=lines(5);

            for level=1:5
                y=D{level};
                m=max(abs(y));
                if m>0, y=y/m; end

                td=(0:length(y)-1)/(fs/(2^level));

                plot(axDetail,td,y, ...
                    'Color',colors(level,:), ...
                    'DisplayName',['D',num2str(level)]);
            end

            hold(axDetail,'off');
            legend(axDetail,'show','Location','eastoutside');
            title(axDetail,'TChart','Color','b');
            grid(axDetail,'on');

            plotSmallBar(axJ1,D{1},'TChart');
            plotSmallBar(axJ2,D{2},'TChart');
            plotSmallBar(axJ3,D{3},'TChart');
            plotSmallBar(axJ4,D{4},'TChart');
            plotSmallBar(axJ5,D{5},'TChart');

            %% K. DETECTION
            cla(axDetect);

            plot(axDetect,1:N,clean, ...
                'Color',[0.23 0.35 0.60], ...
                'LineWidth',1, ...
                'DisplayName','ECG');

            hold(axDetect,'on');

            stairs(axDetect,1:N,gateP, ...
                'LineWidth',1.4,'DisplayName','P');

            stairs(axDetect,1:N,gateQ, ...
                'LineWidth',1.4,'DisplayName','Q');

            stairs(axDetect,1:N,gateR, ...
                'LineWidth',1.7,'DisplayName','R');

            stairs(axDetect,1:N,gateS, ...
                'LineWidth',1.4,'DisplayName','S');

            stairs(axDetect,1:N,gateT, ...
                'LineWidth',1.4,'DisplayName','T');

            hold(axDetect,'off');

            title(axDetect,'TChart','Color','b');
            grid(axDetect,'on');

            % --------------------------------------------
            % Zoom otomatis ke satu beat agar mirip contoh
            % --------------------------------------------
            if ~isempty(R)
                midBeat = ceil(length(R)/2);
                center = R(midBeat);

                zoomLeft  = max(1,center-round(0.35*fs));
                zoomRight = min(N,center+round(0.55*fs));

                xlim(axDetect,[zoomLeft zoomRight]);
            else
                xlim(axDetect,[1 N]);
            end

            ymin=min(clean)-0.10;
            ymax=max([1.10 max(clean)+0.10]);
            ylim(axDetect,[ymin ymax]);

            legend(axDetect,{'ECG','P','Q','R','S','T'}, ...
                'Location','northeast');

            lblStatus.Text = sprintf( ...
                'Selesai\n%s\nPQRST: %d beat', ...
                fileName,length(R));

            tabs.SelectedTab = tabDetection;
            drawnow;

        catch ME
            uialert(fig,ME.message,'Error Processing');
        end
    end

%% helper input
    function ed=addInput(parent,name,y,val)
        uilabel(parent,'Text',name,'Position',[10 y 50 22]);
        ed=uieditfield(parent,'numeric', ...
            'Position',[62 y 85 24], ...
            'Value',val);
    end

end

%% ==============================================================
% MOVING AVERAGE MANUAL
% ==============================================================
function y=movingAverage(x,w)

N=length(x);
y=zeros(size(x));

half=floor(w/2);
cs=[0 cumsum(x)];

for i=1:N
    a=max(1,i-half);
    b=min(N,i+half);
    y(i)=(cs(b+1)-cs(a))/(b-a+1);
end

end

%% ==============================================================
% DWT MANUAL
% ==============================================================
function [A,D]=dwtManual(x,h,g)

L=length(h);
M=floor((length(x)-L)/2)+1;

A=zeros(1,M);
D=zeros(1,M);

out=1;

for n=1:2:(length(x)-L+1)

    a=0;
    d=0;

    for k=1:L
        a=a+x(n+k-1)*h(k);
        d=d+x(n+k-1)*g(k);
    end

    A(out)=a;
    D(out)=d;

    out=out+1;

end

end

%% ==============================================================
% PEAK DETECTION MANUAL
% ==============================================================
function peaks=manualPeaks(x,thr,minDist)

cand=[];

for i=2:length(x)-1

    if x(i)>=x(i-1) && ...
       x(i)>x(i+1) && ...
       x(i)>=thr

        cand(end+1)=i; %#ok<AGROW>
    end
end

if isempty(cand)
    peaks=[];
    return;
end

[~,ord]=sort(x(cand),'descend');

sel=[];

for i=1:length(ord)

    idx=cand(ord(i));
    ok=true;

    for j=1:length(sel)

        if abs(idx-sel(j))<minDist
            ok=false;
            break;
        end
    end

    if ok
        sel(end+1)=idx; %#ok<AGROW>
    end
end

peaks=sort(sel);

end

%% ==============================================================
% AREA/PULSE PQRST
% ==============================================================
function gate=pulseGate(index,N,halfWidth,height)

gate=zeros(1,N);

for k=1:length(index)

    a=max(1,index(k)-halfWidth);
    b=min(N,index(k)+halfWidth);

    gate(a:b)=height;
end

end

%% ==============================================================
% FREQUENCY RESPONSE MANUAL
% ==============================================================
function [w,mag]=manualFR(c,N)

w=linspace(0,pi,N);
mag=zeros(size(w));

for k=1:N

    re=0;
    im=0;

    for n=1:length(c)

        angle=w(k)*(n-1);

        re=re+c(n)*cos(angle);
        im=im-c(n)*sin(angle);
    end

    mag(k)=sqrt(re^2+im^2);
end

end

%% ==============================================================
% BAR KECIL UNTUK j1-j5
% ==============================================================
function plotSmallBar(ax,d,titleText)

cla(ax);

K=min(12,length(d));

if K>0
    bar(ax,1:K,d(1:K),0.75, ...
        'FaceColor',[0.30 0.42 0.65]);
end

title(ax,titleText,'Color','b');
grid(ax,'on');

end
