function program = parseCNCGCode(sourceText,method)
%PARSECNCGCODE Educational XY preview of a restricted G-code subset.
% Supports G0/G1/G2/G3, G90/G91, X/Y, I/J and F. No machine operation.
% X/Y follow active distance mode; arc center I/J offsets ALWAYS start-relative.
% Geometry requires integer grid coordinates and exactly equal arc radii.
    if nargin<2, method='DDA'; end
    if isstring(sourceText), sourceText=char(join(sourceText,newline)); end
    if ~ischar(sourceText)
        error('GCode:Input','G-code must be text or string input.');
    end
    if ~any(strcmp(method,{'DDA','Point-by-Point Comparison'}))
        error('GCode:Method','Choose DDA or Point-by-Point Comparison.');
    end
    lines = regexp(regexprep(sourceText,'\r\n?','\n'),'\n','split');
    segments = struct('Line',{},'Code',{},'Start',{},'End',{}, ...
        'Center',{},'Direction',{},'Points',{},'IsRapid',{});
    absolute = true;
    motion = 0;
    position = [0 0];
    allPoints = position;
    for row=1:numel(lines)
        line = regexprep(lines{row},'\([^)]*\)','');
        line = regexprep(line,';.*$','');
        line = upper(strtrim(line));
        if isempty(line),continue;end
        % CNC word tokenizer rejects unsupported non-space material.
        tokens = regexp(line,'([A-Z])\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+))','tokens');
        if isempty(tokens)
            error('GCode:Syntax','Line %d does not contain valid G-code words.',row);
        end
        residue=regexprep(line,'[A-Z]\s*[+-]?(?:\d+(?:\.\d*)?|\.\d+)','');
        if ~isempty(strtrim(residue))
            error('GCode:Syntax','Invalid token at line %d: %s',row,residue);
        end
        values=struct();
        motionG=[]; distanceG=[];
        for j=1:numel(tokens)
            key=tokens{j}{1}; val=str2double(tokens{j}{2});
            switch key
                case 'G'
                    if ~ismember(val,[0 1 2 3 90 91])
                        error('GCode:Unsupported','Unsupported G%.4g at line %d.',val,row);
                    end
                    if ismember(val,[90 91])
                        distanceG=val;
                    else
                        motionG=val;
                    end
                case {'X','Y','I','J','F','N'}
                    values.(key)=val;
                otherwise
                    error('GCode:Unsupported','Unsupported word %s at line %d.',key,row);
            end
        end
        if ~isempty(distanceG),absolute=(distanceG==90);end
        if ~isempty(motionG),motion=motionG;end
        hasXY=isfield(values,'X')||isfield(values,'Y');
        if ~hasXY, continue; end
        target=position;
        if isfield(values,'X')
            if absolute, target(1)=values.X;
            else, target(1)=target(1)+values.X; end
        end
        if isfield(values,'Y')
            if absolute, target(2)=values.Y;
            else, target(2)=target(2)+values.Y; end
        end
        center=[NaN NaN]; direction='';
        if ismember(motion,[2 3])
            if ~isfield(values,'I')||~isfield(values,'J')
                error('GCode:ArcCenter', ...
                    'Line %d: G02/G03 requires both I and J.',row);
            end
            center=position+[values.I values.J];
            if motion==2, direction='CW';else,direction='CCW';end
            r=interpolatePath('Circular',method,position,target,center,direction);
            pts=r.points;
        elseif motion==1
            r=interpolatePath('Linear',method,position,target,[0 0],'CCW');
            pts=r.points;
        else
            % G00 is shown as a straight dashed rapid traverse; no feed simulation.
            pts=[position;target];
        end
        if size(segments,2)>=500
            error('GCode:Length','Maximum 500 preview segments allowed.');
        end
        s=struct('Line',row,'Code',sprintf('G%02d',motion), ...
            'Start',position,'End',target,'Center',center, ...
            'Direction',direction,'Points',pts,'IsRapid',motion==0);
        segments(end+1)=s; %#ok<AGROW>
        allPoints=[allPoints;pts(2:end,:)]; %#ok<AGROW>
        if size(allPoints,1)>100000
            error('GCode:Length','Maximum 100,000 preview points allowed.');
        end
        position=target;
    end
    if isempty(segments)
        error('GCode:Empty','No XY moves found. Add at least one G00/G01/G02/G03 move.');
    end
    n=numel(segments);
    lineNo=zeros(n,1); command=cell(n,1); sx=zeros(n,1); sy=zeros(n,1);
    ex=zeros(n,1); ey=zeros(n,1); count=zeros(n,1);
    for k=1:n
        s=segments(k);
        lineNo(k)=s.Line;command{k}=s.Code;
        sx(k)=s.Start(1);sy(k)=s.Start(2);
        ex(k)=s.End(1);ey(k)=s.End(2);
        count(k)=size(s.Points,1)-1;
    end
    program.Segments=segments;
    program.Points=allPoints;
    program.Table=table(lineNo,command,sx,sy,ex,ey,count, ...
        'VariableNames',{'Line','GCode','XStart','YStart','XEnd','YEnd','Steps'});
    program.EndPosition=position;
    program.MotionSegments=n;
    program.TotalPoints=size(allPoints,1);
    program.RapidSegments=sum([segments.IsRapid]);
end
