function [res] = st_append_res(varargin)

% ST_APPEND_RES append matching result structures
%
% Use as
%   [res] = st_append_res(res,...)
%
%
% See also ST_SCORINGDESCRIPTIVES

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
fprintf('st_append_res function started\n');

nRes = nargin;

resIDs = cell(nargin,1);


r = varargin{1};
o = r.ori;
t = r.type;

allAppended = true;
anyAppended = false;

for iRes = 1:nRes
    r = varargin{iRes};
    if ~strcmp(r.ori, o) && ~strcmp(r.type, t)
        ft_error('result of origin %s and type %s not compatible with result of origin %s and type %s',r.ori,r.type,o,t);
    end
    wasAppended = false;
    if isfield(r,'appended')
        wasAppended = r.appended;
    end
    anyAppended = anyAppended || wasAppended;
    allAppended = allAppended && wasAppended;
end

if anyAppended
   ft_warning('some results have been appended before, will re-create new resnum column with new ids')
end

iResnum = 1;
restabs = cell(nRes,1);
for iRes = 1:nRes
    r = varargin{iRes};
    wasAppended = false;
    if isfield(r,'appended')
        wasAppended = r.appended;
    end
    if wasAppended
        subResnums = unique(r.table.resnum);
        for iSrdn = 1:numel(subResnums)
            r.table.resnum(r.table.resnum == subResnums(iSrdn)) = iResnum;
            iResnum = iResnum + 1;
        end
        
        resIDs{iRes} = r.table.resnum;
        r.table.resnum = [];

    else
        resIDs{iRes} = repmat(iResnum,size(r.table,1),1);
        iResnum = iResnum + 1;
    end
    
    restabs{iRes} = r.table;
end

resIDs = cat(1, resIDs{:});
resIDs = table(resIDs,'VariableNames',{'resnum'});

restab = cat(1, restabs{:});

restab = cat(2, resIDs ,restab);

res = r;
if isfield(res, 'cfg'); res = rmfield(res,'cfg'); end
res.appended = true;
res.table = restab;

fprintf('st_append_res function finished\n');
toc
memtoc
end