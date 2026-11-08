function result = ddaRegisterTrace(J_vx, J_rx, J_vy, J_ry, nBits, nCycles)
% DDAREGISTERTRACE Simulate the binary accumulator registers of a 2-axis DDA.
%
% result = ddaRegisterTrace('101','000','011','000',3,8)
%
% J_vx / J_vy are constant velocity (increment) registers for the X/Y axes.
% J_rx / J_ry are initial remainder (accumulator) registers for X/Y.
% Each clock adds J_v* to J_r* in unsigned N-bit arithmetic. An overflow
% generates one pulse along the corresponding positive axis, and the low
% N bits are retained in the remainder register. Simultaneous pulses occur.
%
% The output table includes step 0 (the initial state) and each clock's
% updated registers, carries, and cumulative X/Y pulse coordinates.
% This is a teaching model of a fixed-width DDA register, separate from
% the app's geometric circular DDA and point-by-point methods.

    validateattributes(nBits, {'numeric'}, ...
        {'scalar','real','finite','integer','>=',1,'<=',16}, ...
        mfilename,'nBits');
    validateattributes(nCycles, {'numeric'}, ...
        {'scalar','real','finite','integer','>=',1,'<=',20000}, ...
        mfilename,'nCycles');
    nBits = double(nBits);
    nCycles = double(nCycles);
    modulus = 2^nBits;

    [vx,vxText] = parseBinary(J_vx,nBits,'J_vx');
    [rx,rxText] = parseBinary(J_rx,nBits,'J_rx');
    [vy,vyText] = parseBinary(J_vy,nBits,'J_vy');
    [ry,ryText] = parseBinary(J_ry,nBits,'J_ry');

    % Preallocate history including step 0.
    rxHistory = cell(nCycles+1,1);
    ryHistory = cell(nCycles+1,1);
    rxHistory{1} = rxText;
    ryHistory{1} = ryText;
    pulseX = zeros(nCycles+1,1);
    pulseY = zeros(nCycles+1,1);
    x = zeros(nCycles+1,1);
    y = zeros(nCycles+1,1);

    for k = 1:nCycles
        xSum = rx + vx;
        ySum = ry + vy;
        pulseX(k+1) = double(xSum >= modulus);
        pulseY(k+1) = double(ySum >= modulus);
        rx = mod(xSum,modulus);
        ry = mod(ySum,modulus);
        rxHistory{k+1} = dec2bin(rx,nBits);
        ryHistory{k+1} = dec2bin(ry,nBits);
        x(k+1) = x(k) + pulseX(k+1);
        y(k+1) = y(k) + pulseY(k+1);
    end

    constantVX = repmat({vxText},nCycles+1,1);
    constantVY = repmat({vyText},nCycles+1,1);
    result.Table = table((0:nCycles)',constantVX,rxHistory,pulseX, ...
        constantVY,ryHistory,pulseY,x,y, ...
        'VariableNames',{'Step','J_vx','J_rx','PulseX', ...
                         'J_vy','J_ry','PulseY','X','Y'});
    result.Points = [x,y];
    result.PulseX = sum(pulseX);
    result.PulseY = sum(pulseY);
    result.NBits = nBits;
    result.Cycles = nCycles;
    result.Initial = struct('J_vx',vxText,'J_rx',rxText, ...
                            'J_vy',vyText,'J_ry',ryText);
end

function [value,textValue] = parseBinary(inputValue,nBits,label)
    % Binary text is intentional: '011' means 3, not decimal eleven.
    % Numeric input is a decimal integer for callers using MATLAB code.
    if isnumeric(inputValue)
        validateattributes(inputValue,{'numeric'}, ...
            {'scalar','real','finite','integer','>=',0},mfilename,label);
        value = double(inputValue);
        if value >= 2^nBits
            error('DDA:RegisterOverflow','%s does not fit %d bits.',label,nBits);
        end
    else
        if ~(ischar(inputValue) || (isstring(inputValue) && isscalar(inputValue)))
            error('DDA:RegisterType','%s must be binary text or an integer.',label);
        end
        chars = strtrim(char(inputValue));
        if isempty(regexp(chars,'^[01]+$','once'))
            error('DDA:InvalidBinary','%s must contain only 0 and 1.',label);
        end
        if numel(chars)>nBits
            error('DDA:RegisterOverflow','%s exceeds %d bits.',label,nBits);
        end
        value = bin2dec(chars);
    end
    textValue = dec2bin(value,nBits);
end
