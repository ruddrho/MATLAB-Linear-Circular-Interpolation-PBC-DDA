function pts=readCNCWaypoints(fileName)
%READCNCWAYPOINTS Import the start, end and center coordinates for one path.
% CSV/XLSX: header X0,Y0,X1,Y1,CX,CY with one numeric data row.
% MAT: struct named waypoints, containing Start,End,Center numeric 1x2.
    if ~(ischar(fileName)||isstring(fileName))||~isfile(fileName)
        error('Waypoints:File','Provide an existing CSV/XLSX/MAT waypoint file.');
    end
    [~,~,ext]=fileparts(fileName);
    if strcmpi(ext,'.mat')
        data=load(fileName,'waypoints');
        if ~isfield(data,'waypoints')||~isstruct(data.waypoints)
            error('Waypoints:Format','MAT input requires a waypoints struct.');
        end
        pts=data.waypoints;
    elseif ismember(lower(ext),{'.csv','.xlsx'})
        tab=readtable(fileName,'VariableNamingRule','preserve');
        if height(tab)~=1
            error('Waypoints:Format','Waypoint table must contain exactly one row.');
        end
        names={'X0','Y0','X1','Y1','CX','CY'};
        for k=1:numel(names)
            if ~ismember(names{k},tab.Properties.VariableNames)
                error('Waypoints:Format','Required waypoint column: %s',names{k});
            end
        end
        pts.Start=[tab.X0(1) tab.Y0(1)];
        pts.End=[tab.X1(1) tab.Y1(1)];
        pts.Center=[tab.CX(1) tab.CY(1)];
    else
        error('Waypoints:Format','Supported formats are CSV, XLSX and MAT.');
    end
    for key={'Start','End','Center'}
        name=key{1};
        if ~isfield(pts,name)
            error('Waypoints:Format','Missing field %s.',name);
        end
        xy=pts.(name);
        validateattributes(xy,{'numeric'}, ...
            {'real','finite','vector','numel',2,'integer'},mfilename,name);
        if any(abs(xy)>10000)
            error('Waypoints:Range','Waypoint coordinates must be <= 10000.');
        end
        pts.(name)=double(reshape(xy,1,2));
    end
end
