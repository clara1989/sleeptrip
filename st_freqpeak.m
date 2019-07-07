function [freqpeaks1 freqpeaks2] = st_freqpeak(cfg, res)

% ST_FREQPEAK visaully determin peaks in the power spectrum
%
% Use as
%   [freqpeaks1 freqpeaks2] = st_freqpeak(cfg, res)
%   where res is a result structure obtained from ST_POWER of type power_full
%
% Required configuration parameters are:
%   cfg.channel  = Nx1 cell-array with selection of channels (default = 'all'), see FT_CHANNELSELECTION
%   cfg.foilim      = [begin end], frequency band of interest (default = [6 18])
%                     a wider band of 2 frequency steps is required to
%                     perform the analysis, e.g. [5.6 18.4] for a resolution
%                     of 0.2 Hz
%   cfg.peaknum     = number of expected peaks to search for either 1 or 2 (default = 2)
%   cfg.smooth      = smoothing window size in Hz to make the power spectra
%                     appear cleaner (default = 0.3)
%   cfg.minpeakdist = minimal difference between automatically suggested
%                     peaks in Hz (default = 2)
%
% See also ST_POWER

% Copyright (C) 2019-, Frederik D. Weber
%
% This file is part of SleepTrip, see http://www.sleeptrip.org
% for the documentation and details.
%
%    SleepTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    SleepTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    SleepTrip is a branch of FieldTrip, see http://www.fieldtriptoolbox.org
%    and adds funtionality to analyse sleep and polysomnographic data.
%    SleepTrip is under the same license conditions as FieldTrip.
%
%    You should have received a copy of the GNU General Public License
%    along with SleepTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

tic
memtic
fprintf('st_freqpeaks function started\n');

cfg.channel       = ft_getopt(cfg, 'channel', 'all');
cfg.foilim        = ft_getopt(cfg, 'foilim', [6 18]);
cfg.peaknum       = ft_getopt(cfg, 'peaknum', 2);
cfg.smooth        = ft_getopt(cfg, 'smooth', 0.3);
cfg.minpeakdist   = ft_getopt(cfg, 'minpeakdist', 1);

MinFreqStepPadding = 1;


if ~isfield(res, 'type') || ~isfield(res, 'ori')
    ft_error('second argument is not a valid result structure.');
end

if ~(strcmp(res.ori, 'st_power') && strcmp(res.type, 'power_full'))
    ft_error('provided result structure does not match origin of ''st_power'' and type ''power_full'' structure.');
end

hasResnum = false;
if ismember('resnum', res.table.Properties.VariableNames)
    resnums = unique(res.table.resnum);
    hasResnum = true;
else
    resnums = 1;
end
nResnums = numel(resnums);

par_pFreq = {};
par_pPower = {};
par_pPowerChan = {};
par_pPowerChanLabels = {};
par_candSignalFreqPeaks = {};
par_candSignalPowerPeaks = {};
par_tempiDataString = {};
for iResnum = 1:numel(resnums)
    resnum = resnums(iResnum);
    if hasResnum
        temprestab = res.table((res.table.resnum == resnum),:);
    else
        temprestab = res.table;
    end
    
    resolution = min(abs(diff(temprestab.freq)));

    %check if there is sufficient padding and frequency range in the data
    if (min(temprestab.freq) >= cfg.foilim(1)) || (max(temprestab.freq) < cfg.foilim(2))
        ft_error('result structure does not provide sufficient data for requrested frequency range.');
    end
    
    if ~(min(temprestab.freq)+resolution < cfg.foilim(1)) || ~(max(temprestab.freq)-resolution > cfg.foilim(2))
        ft_warning('result structure with resnum %d does have too little padding for finding peaks at the border.',resnum);
    end
    
    temprestab = temprestab(...
        (temprestab.freq >= cfg.foilim(1)) & ...
        (temprestab.freq <= cfg.foilim(2)) ...
        ,:);
    
    power = temprestab.mean_powerDensity_over_segments;
    pFreq = unique(temprestab.freq);
    
    
    tempiDataString = num2str(resnum);
    
    
    pPowerChanLabels = unique(temprestab.channel);
    pPowerChanLabels = ft_channelselection(cfg.channel, pPowerChanLabels);
    
    pPowerChan = zeros(numel(pPowerChanLabels),numel(pFreq));
    for iChan = 1:numel(pPowerChanLabels)
        pPowerChan(iChan,:) = power(strcmp(temprestab.channel,pPowerChanLabels(iChan)))';
    end
    
    pPower = mean(pPowerChan,1);
    
    tempWD = round(cfg.smooth/resolution);
    if tempWD > 1
        if mod(tempWD,2) == 0
            tempWD = tempWD + 1;
        end
        if exist('smooth','file') == 2
            pPower = smooth(pPower,tempWD,'lowess');
            tempiDataString = [tempiDataString ': lowess[' num2str(tempWD) ' point(s)] at f_{res} = ' num2str(resolution) ' Hz.'];
            for iChannel = 1:length(pPowerChanLabels)
                pPowerChan(iChannel,:) = smooth(pPowerChan(iChannel,:),tempWD,'lowess');
            end
            
        else
            pPower = smoothwd(pPower,tempWD);
            tempiDataString = [tempiDataString ': mean[' num2str(tempWD) ' points(s)] at f_{res} = ' num2str(resolution) ' Hz.'];
            for iChannel = 1:length(pPowerChanLabels)
                pPowerChan(iChannel,:) = smoothwd(pPowerChan(iChannel,:),tempWD);
            end
        end
    end
    
    [candSignalPowerPeaks, candSignalPowerPeaksSamples] = findpeaks(pPower,'MINPEAKHEIGHT',0,'MINPEAKDISTANCE',ceil(cfg.minpeakdist/resolution),'SORTSTR','descend');
    
    
    tempValidSamples = (candSignalPowerPeaksSamples >= MinFreqStepPadding) & (candSignalPowerPeaksSamples <= (length(pFreq) - MinFreqStepPadding));
    if length(tempValidSamples) < 1
        candSignalPowerPeaksSamples(candSignalPowerPeaksSamples <= MinFreqStepPadding) = MinFreqStepPadding;
        candSignalPowerPeaksSamples(candSignalPowerPeaksSamples >= (length(pFreq) - MinFreqStepPadding)) = (length(pFreq) - MinFreqStepPadding);
    else
        candSignalPowerPeaksSamples = candSignalPowerPeaksSamples(tempValidSamples);
    end
    candSignalPowerPeaks = candSignalPowerPeaks(tempValidSamples);
    candSignalFreqPeaks = pFreq(candSignalPowerPeaksSamples);
    
    if (cfg.peaknum ~= length(candSignalFreqPeaks))
        tempiDataString = [tempiDataString ' Peak(s) not trusted!'];
    end
    %fill with pseudo peaks if necessary
    tempNpeaks = length(candSignalFreqPeaks);
    if tempNpeaks == 0
        candSignalPowerPeaks(1) = pPower(1);
        candSignalFreqPeaks(1) = pFreq(1);
        tempNpeaks = 1;
    end
    if (cfg.peaknum > tempNpeaks)
        for iNP = (tempNpeaks+1):cfg.peaknum
            candSignalFreqPeaks(iNP) = candSignalFreqPeaks(tempNpeaks);
            candSignalPowerPeaks(iNP) = candSignalPowerPeaks(tempNpeaks);
        end
    end
    
    candSignalPowerPeaks = candSignalPowerPeaks(1:cfg.peaknum);
    candSignalFreqPeaks = candSignalFreqPeaks(1:cfg.peaknum);
    
    [candSignalFreqPeaks, tempNewPeakOrder] = sort(candSignalFreqPeaks,'ascend');
    
    candSignalPowerPeaks = candSignalPowerPeaks(tempNewPeakOrder);
    
    %tempIndex = find(iDatas == iData);
    %outputFreqPeaks(tempIndex,1:cfg.peaknum) = candSignalFreqPeaks(1:cfg.peaknum);
    %outputFreqPeaks(tempIndex,1:cfg.peaknum) = spd_peakdet_gui(pFreq,pPower,candSignalFreqPeaks(1:cfg.peaknum),candSignalPowerPeaks(1:cfg.peaknum),tempiDataString);
    
    tempiDataString = sprintf('%s\n%s',tempiDataString,strrep(strjoin(pPowerChanLabels',','),'_','\_'));
    
    par_pFreq{resnum} = pFreq;
    par_pPower{resnum} = pPower;
    par_pPowerChan{resnum} = pPowerChan;
    par_pPowerChanLabels{resnum} = pPowerChanLabels;
    par_candSignalFreqPeaks{resnum} = candSignalFreqPeaks(1:cfg.peaknum);
    par_candSignalPowerPeaks{resnum} = candSignalPowerPeaks(1:cfg.peaknum);
    par_tempiDataString{resnum} = tempiDataString;
    
end


outputFreqPeaks = zeros(nResnums,cfg.peaknum)-1;
tempAllAccepted = false;
conseciData = 1;

while ~tempAllAccepted
    iData = resnums(conseciData);
    tempIndex = find(resnums == iData);
    if any(outputFreqPeaks(tempIndex,1:cfg.peaknum) < 0)
        outputFreqPeaks(tempIndex,1:cfg.peaknum) = spd_peakdet_gui_new(par_pFreq{conseciData},par_pPower{conseciData},par_pPowerChan{conseciData},par_pPowerChanLabels{conseciData},par_candSignalFreqPeaks{conseciData},par_candSignalPowerPeaks{conseciData},par_tempiDataString{conseciData},'',iData);
    end
    tempAllAccepted = ~any(any(outputFreqPeaks(:,1:cfg.peaknum) < 0));
    conseciData = conseciData + 1;
    if conseciData > numel(resnums)
        conseciData = 1;
    end
end

freqpeaks1 = outputFreqPeaks(:,1);
freqpeaks2 = freqpeaks1;
freqpeaks2(:) = NaN;

if cfg.peaknum == 2
    freqpeaks2 = outputFreqPeaks(:,2);
end

fprintf('st_freqpeaks function finished\n');
toc
memtoc
end
