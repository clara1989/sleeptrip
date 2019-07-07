function [fh] = st_hypnoplot(cfg, scoring)

% ST_HYPNOPLOT plots a hypnogram from the scoring
%
% Use as
%   [fh] = st_hypnoplot(cfg,scoring)
%
%   scoring is a structure provided by ST_READ_SCORING
%   it returns the figure handle
%
%   config file can be empty, e.g. cfg = []
%
% Optional configuration parameters are
%   cfg.plotsleeponset         = string, plot an indicator of sleep onset either 'yes' or 'no' (default = 'yes')
%   cfg.plotsleepoffset        = string, plot an indicator of sleep offset either 'yes' or 'no' (default = 'yes')
%   cfg.plotunknown            = string, plot unscored/unkown epochs or not either 'yes' or 'no' (default = 'yes')
%   cfg.sleeponsetdef          = string, sleep onset either 'N1' or 'N1_NR' or 'N1_XR' or
%                                'NR' or 'NR' or 'XR', see ST_SCORINGDESCRIPTIVES for details (default = 'N1_XR')
%   cfg.title                  = string, title of the figure to export the figure
%   cfg.timeticksdiff          = scalar, time difference in minutes the ticks are places from each other (default = 30);
%   cfg.timemin                = scalar, minimal time in minutes the ticks 
%                                have, e.g. 480 min, will plot tick at least to 480 min (default = 0);
%   cfg.considerdataoffset     = string, 'yes' or 'no' if dataoffset is represented in time axis (default = 'yes');
%
% If you wish to export the figure then define also the following
%   cfg.figureoutputfile       = string, file to export the figure
%   cfg.figureoutputformat     = string, either 'png' or 'epsc' or 'svg' or 'tiff' or
%                                'pdf' or 'bmp' or 'fig' (default = 'png')
%   cfg.figureoutputunit       = string, dimension unit (1 in = 2.54 cm) of hypnograms.
%                                either 'points' or 'normalized' or 'inches'
%                                or 'centimeters' or 'pixels' (default =
%                                'inches')
%   cfg.figureoutputwidth      = scalar, choose format dimensions in inches
%                                (1 in = 2.54 cm) of hypnograms. (default = 9)
%   cfg.figureoutputheight     = scalar, format dimensions in inches (1 in = 2.54 cm) of hypnograms. (default = 3)
%   cfg.figureoutputresolution = scalar, choose resolution in pixesl per inches (1 in = 2.54 cm) of hypnograms. (default = 300)
%   cfg.figureoutputfontsize   = scalar, Font size in units stated in
%                                parameter cfg.figureoutputunit (default = 0.1)
%
%  Events can be plotted using the following options
%
%   cfg.eventtimes             = a Nx1 cell containing 1x? vectors of event time points (in seconds)
%                                 {[1.5, 233.2, 455.6]; ...
%                                  [98, 3545.9]; ...
%                                  [393.4, 425.8, 900.0, 4001.01]}
%   cfg.eventlabels            = Nx1 cellstr with the labels to the events corresponding to the rows in cfg.eventstimes
%   cfg.eventvalues            = a Nx1 cell containing 1x? vectors of event
%                                values (e.g. amplitude)
%                                 {[20.3, 23.2, 45.6]; ...
%                                  [18, 35.9]; ...
%                                  [39.1, 42.5, 80.0, 42.1]}
%   cfg.eventranges            = a Nx1 cell containing 1x2 vectors of event
%                                values ranges (e.g. min and max of amplitude)
%                                 {[20 40]; ...
%                                  [18, 36]; ...
%                                  [39, 80.0]}
%
%
%
% See also ST_READ_SCORING

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

% set the defaults
cfg.title                   = ft_getopt(cfg, 'title', '');
cfg.timeticksdiff           = ft_getopt(cfg, 'timeticksdiff', 30);
cfg.timemin                 = ft_getopt(cfg, 'timemin', 0);
cfg.considerdataoffset      = ft_getopt(cfg, 'considerdataoffset', 'yes');
cfg.plotsleeponset          = ft_getopt(cfg, 'plotsleeponset', 'yes');
cfg.plotsleepoffset         = ft_getopt(cfg, 'plotsleepoffset', 'yes');
cfg.plotunknown             = ft_getopt(cfg, 'plotunknown', 'yes');
cfg.sleeponsetdef           = ft_getopt(cfg, 'sleeponsetdef', 'N1_XR');
cfg.figureoutputformat      = ft_getopt(cfg, 'figureoutputformat', 'png');
cfg.figureoutputunit        = ft_getopt(cfg, 'figureoutputunit', 'inches');
cfg.figureoutputwidth       = ft_getopt(cfg, 'figureoutputwidth', 9);
cfg.figureoutputheight      = ft_getopt(cfg, 'figureoutputheight', 3);
cfg.figureoutputresolution  = ft_getopt(cfg, 'figureoutputresolution', 300);
cfg.figureoutputfontsize    = ft_getopt(cfg, 'figureoutputfontsize', 0.1);


if (isfield(cfg, 'eventtimes') && ~isfield(cfg, 'eventlabels')) || (~isfield(cfg, 'eventtimes') && isfield(cfg, 'eventlabels'))  
    ft_error('both cfg.eventtimes and cfg.eventlabels have to be defined togehter.');
end

if isfield(cfg, 'eventtimes')
    if size(cfg.eventtimes,1) ~=  numel(cfg.eventlabels)
        ft_error('dimensions of cfg.eventtimes and cfg.eventlabels do not match.');
    end
end

if (isfield(cfg, 'eventvalues') && ~isfield(cfg, 'eventtimes')) 
    ft_error('both cfg.eventvalues needs a cfg.eventtimes to be defined.');
end

if (isfield(cfg, 'eventvalues') && ~isfield(cfg, 'eventranges')) || (~isfield(cfg, 'eventvalues') && isfield(cfg, 'eventranges'))  
    ft_error('both cfg.eventvalues and cfg.eventranges have to be defined togehter.');
end

if isfield(cfg, 'eventvalues')
    if size(cfg.eventtimes,1) ~=  numel(cfg.eventvalues)
        ft_error('dimensions of cfg.eventtimes and cfg.eventvalues do not match.');
    end
end

if isfield(cfg, 'eventranges')
    if size(cfg.eventtimes,1) ~=  numel(cfg.eventranges)
        ft_error('dimensions of cfg.eventtimes and cfg.eventranges do not match.');
    end
end

hasLightsOff = false;
saveFigure   = false;

if strcmp(cfg.considerdataoffset, 'yes')
    offsetseconds = scoring.dataoffset;
else
    offsetseconds = 0;
end

if isfield(cfg, 'figureoutputfile')
    saveFigure = true;
end

if isfield(scoring, 'lightsoff')
    hasLightsOff = true;
end

dummySampleRate = 100;
epochLengthSamples = scoring.epochlength * dummySampleRate;
nEpochs = numel(scoring.epochs);

if hasLightsOff
    lightsOffSample = scoring.lightsoff*dummySampleRate;
else
    lightsOffSample = 0;
end

%convert the sleep stages to hypnogram numbers
hypn = [cellfun(@(st) sleepStage2hypnNum(st,~istrue(cfg.plotunknown)),scoring.epochs','UniformOutput',1) ...
    scoring.excluded'];


hypnStages = [cellfun(@sleepStage2str,scoring.epochs','UniformOutput',0) ...
    cellfun(@sleepStage2str_alt,scoring.epochs','UniformOutput',0) ...
    cellfun(@sleepStage2str_alt2,scoring.epochs','UniformOutput',0)];


hypnEpochs = 1:numel(scoring.epochs);
hypnEpochsBeginsSamples = (((hypnEpochs - 1) * epochLengthSamples) + 1)';

%onsetCandidateIndex = getSleepOnsetEpoch(hypnStages,hypnEpochsBeginsSamples,lightsOffSample,cfg.sleeponsetdef);

[onsetCandidateIndex preOffsetCandidate onsetepoch] = st_sleeponset(cfg,scoring);

if isempty(preOffsetCandidate)
    preOffsetCandidate = nEpochs;
end



%%% plot hypnogram figure

switch scoring.standard
    case 'aasm'
        plot_exclude_offset = -5;
        yTickLabel = {'?' 'A'      'W'    'R'  'N1' 'N2' 'N3'       'Excl'};
        yTick      = [1.5  1        0     -0.5  -1   -2   -3         plot_exclude_offset];
    case 'rk'
        plot_exclude_offset = -7;
        yTickLabel = {'?' 'A' 'MT' 'Wake' 'REM' 'S1' 'S2' 'S3' 'S4' 'Excl'};
        yTick      = [1.5  1   0.5  0     -0.5  -1   -2   -3   -4   plot_exclude_offset];
    otherwise
        ft_error('scring standard ''%s'' not supported for ploting', scoring.standard);
end

[hypn_plot_interpol hypn_plot_interpol_exclude] = interpolate_hypn_for_plot(hypn,epochLengthSamples,plot_exclude_offset);

if ~istrue(cfg.plotunknown)
    tempremind = strcmp(yTickLabel,'?');
    yTickLabel(tempremind) = [];
    yTick(tempremind) = [];
end

hhyp = figure;
axh = gca;
set(hhyp,'color',[1 1 1]);
set(axh,'FontUnits',cfg.figureoutputunit)
set(axh,'Fontsize',cfg.figureoutputfontsize);

x_time = (1:length(hypn_plot_interpol))/(dummySampleRate);
x_time = x_time + offsetseconds;
x_time = x_time/60; % minutes

x_time_hyp = x_time(1:length(hypn_plot_interpol));

plot(axh,x_time_hyp,hypn_plot_interpol,'Color',[0 0 0])
hold(axh,'on');

eventTimeMaxSeconds = cfg.timemin*60;
offset_step = 0.5;
eventHeight = 0.4;
offset_event_y = max(yTick);

if isfield(cfg, 'eventtimes')
    
    nEvents = numel(cfg.eventtimes);
    tempcolors = lines(nEvents);
    for iEventTypes = 1:nEvents
        offset_event_y = offset_event_y + offset_step;
        currEvents = cfg.eventtimes{iEventTypes};
        currEventLabel = cfg.eventlabels{iEventTypes};
        
        yTick = [offset_event_y yTick];
        yTickLabel = {currEventLabel yTickLabel{:}};
        
        color = tempcolors(iEventTypes,:);
        eventTimeMaxSeconds = max([eventTimeMaxSeconds currEvents]);
        temp_x = (currEvents/60)';
        temp_y = repmat(offset_event_y,numel(currEvents),1);
        if isfield(cfg, 'eventvalues')
            currEventValues = cfg.eventvalues{iEventTypes};
            currEventRanges = cfg.eventranges{iEventTypes};
            event_scale = fw_normalize(currEventValues, min(currEventRanges),  max(currEventRanges), 0.1, 1)';
            text(max(temp_x)+1,temp_y(1),['[' num2str(min(currEventRanges)) ' ' num2str(max(currEventRanges)) ']']);
        else
        	event_scale = 1;
        end
        temp_plot_y = [temp_y-(eventHeight*event_scale)/2 temp_y+(eventHeight*event_scale)/2]';
        plot(axh,[temp_x temp_x]',temp_plot_y,'Color',color)
    end
end


temp_max_y = max(yTick);

if isfield(cfg, 'eventtimes')
    temp_max_y = temp_max_y + eventHeight;
end

if strcmp(cfg.plotsleeponset, 'yes')
    if onsetCandidateIndex ~= -1
        onset_time = (onsetCandidateIndex-0.5)*(scoring.epochlength/60) + (offsetseconds/60);%in minutes
        onset_y_coord_offset = 0.2;
        onset_y_coord = hypn_plot_interpol(find(x_time >=onset_time,1,'first'))+onset_y_coord_offset;
        hold(axh,'on');
        scatter(axh,onset_time,onset_y_coord,'filled','v','MarkerFaceColor',[0 1 0])
    end
end

offset_time = (preOffsetCandidate+0.5)*(scoring.epochlength/60)+(offsetseconds/60);%in minutes
offset_y_coord_offset = 0.2;
offset_y_coord = hypn_plot_interpol(find(x_time <=offset_time,1,'last'))+offset_y_coord_offset;
hold(axh,'on');
if strcmp(cfg.plotsleepoffset, 'yes')
    scatter(axh,offset_time,offset_y_coord,'filled','^','MarkerFaceColor',[0 0 1])
end
plot(axh,x_time_hyp,hypn_plot_interpol_exclude,'Color',[1 0 0])
xlim(axh,[0 (max([max(x_time),cfg.timemin,eventTimeMaxSeconds/60]))]);
ylabel(axh,'Stages');
ylim(axh,[plot_exclude_offset temp_max_y])

set(axh, 'yTick', flip(yTick));
set(axh, 'yTickLabel', flip(yTickLabel));
set(axh,'TickDir','out');
xTick = [0:cfg.timeticksdiff:(max([max(x_time),cfg.timemin,eventTimeMaxSeconds/60]))];
set(axh, 'xTick', xTick);
set(axh, 'box', 'off')

%     begsample = 0;
%     endsample = 0;
%     x_pos_begin = x_time(begsample);
%     x_pos_end = x_time(endsample);
%     x_pos = [x_pos_begin x_pos_end x_pos_end x_pos_begin];
%     y_pos = [plot_exclude_offset plot_exclude_offset 1 1];
%     pos_now = patch(x_pos,y_pos,[0.5 0.25 1],'parent',axh);
%     set(pos_now,'FaceAlpha',0.4);
%     set(pos_now,'EdgeColor','none');

%     line([x_pos_begin x_pos_begin],[plot_exclude_offset temp_max_y],'color',[0.25 0.125 1],'parent',axh);

%titleName = sprintf('Hypnogram_datasetnum_%d_file_%d',iData,iHyp);
set(hhyp, 'Name', cfg.title);

hold(axh,'off')

title(cfg.title,'Interpreter','none');
xlabel('Time [min]');
ylabel('Sleep stage');


figure_width = cfg.figureoutputwidth;     % Width in inches
figure_height = cfg.figureoutputheight;    % Height in inches
pos = get(hhyp, 'Position');

%set(hhyp, 'Position', [pos(1) pos(2) figure_width*str2num(cfg.figureoutputresolution), figure_height*str2num(cfg.figureoutputresolution)]); %<- Set size
set(hhyp, 'Position', [pos(1) pos(2) figure_width*100, figure_height*100]); %<- Set size
% Here we preserve the size of the image when we save it.
set(hhyp,'InvertHardcopy','on');
set(hhyp,'PaperUnits', cfg.figureoutputunit);

%set(hhyp,'PaperPositionMode','Auto')
set(hhyp,'PaperSize',[figure_width, figure_height])

papersize = get(hhyp, 'PaperSize');
left = (papersize(1)- figure_width)/2;
bottom = (papersize(2)- figure_height)/2;
myfiguresize = [left, bottom, figure_width, figure_height];
set(hhyp,'PaperPosition', myfiguresize);
set(hhyp,'PaperOrientation', 'portrait');


if saveFigure
    switch cfg.figureoutputformat
        case 'fig'
            saveas(hhyp, [cfg.figureoutputfile '.fig']);
        case 'eps'
            print(hhyp,['-d' 'epsc'],['-r' num2str(cfg.figureoutputresolution)],[cfg.figureoutputfile]);
        otherwise
            print(hhyp,['-d' cfg.figureoutputformat],['-r' num2str(cfg.figureoutputresolution)],[cfg.figureoutputfile]);
    end
end
fh = hhyp;

%%% plot hypnogram figure end


end


function st = sleepStage2hypnNum(st,unknownIsNaN)
switch st
    case {'W' 'w' 'Wake' 'wake' 'WAKE' '0'}
        st = 0;
    case {'S1' 'N1' 'stage 1' 'Stage 1' 'Stage1' 'STAGE 1' 'STAGE1' 'S 1' 'Stadium 1' 'STADIUM 1' 'STADIUM1' '1'}
        st = -1;
    case {'S2' 'N2' 'stage 2' 'Stage 2' 'Stage2' 'STAGE 2' 'STAGE2' 'S 2' 'Stadium 2' 'STADIUM 2' 'STADIUM2' '2' }
        st = -2;
    case {'S3' 'N3' 'stage 3' 'Stage 3' 'Stage3' 'STAGE 3' 'STAGE3' 'S 3' 'Stadium 3' 'STADIUM 3' 'STADIUM3' '3' 'SWS'}
        st = -3;
    case {'S4' 'N4' 'stage 4' 'Stage 4' 'Stage4' 'STAGE 4' 'STAGE4' 'S 4' 'Stadium 4' 'STADIUM 4' 'STADIUM4' '4' 'SWS4'}
        st = -4;
    case {'REM' 'R' 'r' 'Rem' 'rem' 'Stage 5' 'Stage5' 'STAGE 5' 'STAGE5' 'S 5' 'Stadium 5' 'STADIUM 5' 'STADIUM5' '5'}
        st = -0.5;
    case {'MT' 'mt' 'movement' 'Movement' 'Movement Time' 'MovementTime' '8'}
        st = 0.5;
    case {'A' 'a' 'Artifact' 'Artefact' 'artifact' 'artefact' 'Artf' 'Artif.'}
        st = 1;
    case {'?' '???' 'unknown', 'Unknown' '-'  'X' 'x'}
        if unknownIsNaN
            st = NaN;
        else
            st = 1.5;
        end
    otherwise
        if unknownIsNaN
            st = NaN;
        else
            st = 1.5;
        end
end
end



function [hypn_plot_interpol hypn_plot_interpol_exclude] = interpolate_hypn_for_plot(hypn,epochLengthSamples,plot_exclude_offset)
hypn_plot = hypn;
hypn_plot_exclude = hypn_plot(:,2) ;
%hypn_plot_exclude = hypn_plot_exclude*0.5;
%hypn_plot_exclude(hypn_plot_exclude > 1) = 1.35;
hypn_plot = hypn_plot(:,1) ;
hypn_plot_interpol = [];
hypn_plot_interpol_exclude = [];
for iEp = 1:length(hypn_plot)
    temp_samples = repmat(hypn_plot(iEp),epochLengthSamples,1);
    if (hypn_plot(iEp) == -0.5) %REM
        temp_samples(1:2:end) = -0.3;
        temp_samples(2:2:end) = -0.7;
        %                 for iSamp = 1:length(temp_samples)
        %                     if mod(iSamp,2) == 0
        %                         temp_samples(iSamp) = -0.20;
        %                     else
        %                         temp_samples(iSamp) = -0.70;
        %                     end
        %                 end
    end
    
    hypn_plot_interpol = [hypn_plot_interpol; temp_samples];
    
    temp_samples_exclude = repmat(plot_exclude_offset+hypn_plot_exclude(iEp),epochLengthSamples,1);
    if (hypn_plot_exclude(iEp) > 0) %excluded
        for iSamp = 1:length(temp_samples_exclude)
            if mod(iSamp,2) == 1
                temp_samples_exclude(iSamp) = plot_exclude_offset;
            end
        end
    end
    hypn_plot_interpol_exclude = [hypn_plot_interpol_exclude; temp_samples_exclude];
end

end