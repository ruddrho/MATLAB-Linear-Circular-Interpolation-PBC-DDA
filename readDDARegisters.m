function config = readDDARegisters(fileName)
% READDDAREGISTERS Import an X/Y fixed-width DDA register configuration.
%
% Supported formats:
%   CSV, TSV, TXT: header/value row, e.g.
%      J_vx,J_rx,J_vy,J_ry,NBits,Cycles
%      101,000,011,000,3,8
%   CSV, TSV, TXT: one setting per line (J_vx=101, etc.)
%   XLSX: header/value row; format binary cells as text to preserve zeros.
%   MAT: a scalar struct called 'registers' or 'config' with same fields.
%
% Values in CSV/TXT/XLSX are BINARY digit strings. In particular 011 is
% three in binary; read/write leading zero digits for clarity.

    if ~(ischar(fileName) || (isstring(fileName) && isscalar(fileName)))
        error('DDA:ImportPath','File name must be text.');
    end
    fileName = char(fileName);
    if ~isfile(fileName)
        error('DDA:ImportNotFound','File not found: %s',fileName);
    end
    [~,~,ext] = fileparts(fileName);
    ext = lower(ext);
    switch ext
        case {'.csv','.tsv','.txt'}
            entries = readPlainText(fileName);
        case '.xlsx'
            values = readcell(fileName);
            if size(values,1)<2
                error('DDA:ImportFormat','XLSX requires a header and one data row.');
            end
            entries = rowToStruct(values(1,:),values(2,:));
        case '.mat'
            loaded = load(fileName);
            if isfield(loaded,'registers')
                entries = loaded.registers;
            elseif isfield(loaded,'config')
                entries = loaded.config;
            else
                error('DDA:ImportFormat', ...
                    'MAT file must contain a struct named registers or config.');
            end
        otherwise
            error('DDA:ImportFormat','Unsupported file type: %s',ext);
    end
    if ~isstruct(entries) || ~isscalar(entries)
        error('DDA:ImportFormat','Register input must be one record/struct.');
    end
    names = fieldnames(entries);
    normalized = regexprep(lower(string(names)),'[^a-z0-9]','');
    required = {'J_vx','J_rx','J_vy','J_ry'};
    config = struct();
    for k=1:numel(required)
        key = regexprep(lower(required{k}),'[^a-z0-9]','');
        idx = find(strcmp(normalized,key),1);
        if isempty(idx)
            error('DDA:ImportMissing','Missing column or field: %s',required{k});
        end
        config.(required{k}) = normalizeBinary(entries.(names{idx}),required{k});
    end
    config.NBits = 3;
    config.Cycles = NaN;
    idxBits = find(strcmp(normalized,'nbits'),1);
    if ~isempty(idxBits)
        config.NBits = parsePositiveInteger(entries.(names{idxBits}),'NBits');
    else
        config.NBits = max([numel(config.J_vx),numel(config.J_rx), ...
                            numel(config.J_vy),numel(config.J_ry)]);
    end
    idxCycles = find(strcmp(normalized,'cycles'),1);
    if ~isempty(idxCycles)
        config.Cycles = parsePositiveInteger(entries.(names{idxCycles}),'Cycles');
    else
        config.Cycles = 2^config.NBits;
    end

    % Reuse model validation for imported binary widths and clock limits.
    ddaRegisterTrace(config.J_vx,config.J_rx,config.J_vy,config.J_ry, ...
        config.NBits,config.Cycles);
end

function fields = readPlainText(fileName)
    data = strrep(fileread(fileName),sprintf('\r'),'');
    lines = regexp(data,'\n','split');
    lines = lines(~cellfun(@(s) isempty(strtrim(s)),lines));
    lines = lines(~cellfun(@(s) startsWith(strtrim(s),'#'),lines));
    if isempty(lines)
        error('DDA:ImportEmpty','The file has no register values.');
    end
    % Key/value rows are convenient for hand-editing TXT files.
    if contains(lines{1},'=')
        fields = struct();
        for i=1:numel(lines)
            pieces = strsplit(lines{i},'=');
            if numel(pieces)~=2
                error('DDA:ImportFormat','Expected Key=Value at line %d.',i);
            end
            key = strtrim(pieces{1});
            if ~isvarname(key)
                error('DDA:ImportFormat','Invalid field name %s.',key);
            end
            fields.(key) = strtrim(pieces{2});
        end
        return;
    end
    if numel(lines)<2
        error('DDA:ImportFormat','Include a header row and a data row.');
    end
    if contains(lines{1},sprintf('\t'))
        delimiter = sprintf('\t');
    elseif contains(lines{1},';')
        delimiter = ';';
    else
        delimiter = ',';
    end
    headers = strsplit(lines{1},delimiter);
    values = strsplit(lines{2},delimiter);
    fields = rowToStruct(headers,values);
end

function entries = rowToStruct(headers,values)
    if numel(headers)~=numel(values)
        error('DDA:ImportFormat','Header and data column counts must match.');
    end
    entries = struct();
    for j=1:numel(headers)
        key = strtrim(char(string(headers{j})));
        key = regexprep(key,'^"|"$','');
        if ~isvarname(key)
            error('DDA:ImportFormat','Invalid column name: %s',key);
        end
        value = values{j};
        if ischar(value) || isstring(value)
            value = strtrim(char(string(value)));
            value = regexprep(value,'^"|"$','');
        end
        entries.(key) = value;
    end
end

function value = normalizeBinary(raw,label)
    if ischar(raw) || (isstring(raw) && isscalar(raw))
        value = strtrim(char(string(raw)));
    elseif isnumeric(raw) && isscalar(raw) && isfinite(raw) ...
            && raw==round(raw) && raw>=0
        % A numeric spreadsheet cell 11 is interpreted as digits "11",
        % not decimal eleven. To import numeric decimal register values,
        % use binary text (e.g. "101") or a MAT struct with binary text.
        value = sprintf('%.0f',raw);
    else
        error('DDA:ImportValue','%s must be a binary digit string.',label);
    end
    if isempty(regexp(value,'^[01]+$','once'))
        error('DDA:ImportValue','%s must contain only binary 0/1 digits.',label);
    end
end

function value = parsePositiveInteger(raw,label)
    if ischar(raw) || isstring(raw)
        value = str2double(char(string(raw)));
    else
        value = double(raw);
    end
    if ~isscalar(value) || ~isfinite(value) || value~=round(value) || value<1
        error('DDA:ImportValue','%s must be a positive integer.',label);
    end
end
