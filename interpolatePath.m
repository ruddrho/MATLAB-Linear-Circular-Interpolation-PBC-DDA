function result = interpolatePath(pathType, method, startXY, endXY, centerXY, direction)
%INTERPOLATEPATH Educational 2-D CNC reference-pulse interpolation.
% result = interpolatePath(pathType, method, startXY, endXY, centerXY, direction)
%
% Inputs are integer step-grid positions, NOT machine millimeters.
% pathType:  'Linear' or 'Circular'
% method:    'Point-by-Point Comparison' or 'DDA'
% direction: 'CCW' or 'CW' (circular only)
%
% Output fields:
%   points      Nx2 commanded integer grid points including both endpoints
%   ideal       Mx2 samples of the geometrically ideal reference path
%   deviation   Nx1 distance from ideal line/circle (grid units)
%   info        struct with diagnostic summary
%
% The DDA circle uses coupled forward-integration accumulators with a
% length-preserving normalization. Both methods are pedagogical pulse
% interpolators and are not real-time machine-control implementations.

    pathType = char(string(pathType));
    method = char(string(method));
    direction = char(string(direction));
    startXY = validateXY(startXY, 'startXY');
    endXY = validateXY(endXY, 'endXY');
    centerXY = validateXY(centerXY, 'centerXY');

    if ~any(strcmp(pathType, {'Linear','Circular'}))
        error('Interpolation:Mode','Path type must be Linear or Circular.');
    end
    if ~any(strcmp(method, {'Point-by-Point Comparison','DDA'}))
        error('Interpolation:Method','Method must be Point-by-Point Comparison or DDA.');
    end
    if ~any(strcmp(direction, {'CCW','CW'}))
        error('Interpolation:Direction','Direction must be CCW or CW.');
    end

    if strcmp(pathType, 'Linear')
        if strcmp(method, 'DDA')
            points = linearDDA(startXY, endXY);
        else
            points = linearPBC(startXY, endXY);
        end
        ideal = [linspace(startXY(1), endXY(1), 400)', ...
                 linspace(startXY(2), endXY(2), 400)'];
        dx = endXY - startXY;
        d = hypot(dx(1), dx(2));
        if d == 0
            deviation = zeros(size(points,1),1);
        else
            rel = points - startXY;
            deviation = abs(rel(:,1)*dx(2) - rel(:,2)*dx(1)) / d;
        end
        sweep = NaN;
    else
        radii2 = [sum((startXY-centerXY).^2), sum((endXY-centerXY).^2)];
        radius = sqrt(radii2(1));
        if radius < 2
            error('Interpolation:Radius','Circular paths need radius >= 2 grid units.');
        end
        if radii2(1) ~= radii2(2)
            error('Interpolation:ArcRadius', ...
                'Start and end must have exactly equal radii from center on the integer grid.');
        end
        s = 1;
        if strcmp(direction,'CW'), s = -1; end
        a0 = atan2(startXY(2)-centerXY(2), startXY(1)-centerXY(1));
        a1 = atan2(endXY(2)-centerXY(2), endXY(1)-centerXY(1));
        sweep = mod(s*(a1-a0), 2*pi);
        if isequal(startXY,endXY), sweep = 2*pi; end % full circle
        if strcmp(method, 'DDA')
            points = circularDDA(startXY, endXY, centerXY, s, sweep);
        else
            points = circularPBC(startXY, endXY, centerXY, s, sweep);
        end
        a = a0 + s*linspace(0,sweep,600)';
        ideal = centerXY + radius*[cos(a),sin(a)];
        deviation = abs(hypot(points(:,1)-centerXY(1), ...
                              points(:,2)-centerXY(2)) - radius);
    end

    steps = size(points,1)-1;
    if steps == 0
        pathLength = 0;
    else
        diffXY = diff(points,1,1);
        pathLength = sum(hypot(diffXY(:,1),diffXY(:,2)));
    end
    result.points = points;
    result.ideal = ideal;
    result.deviation = deviation;
    result.info = struct('PulseCycles',steps, 'PathLength',pathLength, ...
       'MaxDeviation',max(deviation), 'SweepDegrees',sweep*180/pi, ...
       'PathType',pathType, 'Method',method);
end

function xy = validateXY(xy, variableName)
    validateattributes(xy,{'numeric'},{'real','finite','vector','numel',2}, ...
        mfilename,variableName);
    xy = double(reshape(xy,1,2));
    if any(xy ~= round(xy))
        error('Interpolation:Grid','All coordinates must be integer grid units.');
    end
    if any(abs(xy)>10000)
        error('Interpolation:Range','Coordinate magnitude cannot exceed 10,000.');
    end
end

function points = linearPBC(p0,p1)
% One-axis-per-pulse point-by-point decision using signed line error.
    delta = p1-p0;
    ad = abs(delta);
    s = sign(delta);
    count = sum(ad);
    guardSize(count);
    points = zeros(count+1,2);
    points(1,:) = p0;
    p = p0;
    for k = 1:count
        xSteps = (p(1)-p0(1))*s(1);
        ySteps = (p(2)-p0(2))*s(2);
        F = xSteps*ad(2) - ySteps*ad(1);
        if (xSteps<ad(1)) && (ySteps>=ad(2) || F<=0)
            p(1) = p(1)+s(1);
        else
            p(2) = p(2)+s(2);
        end
        points(k+1,:) = p;
    end
end

function points = linearDDA(p0,p1)
% Two integer accumulator registers; both axes can pulse on one tick.
    delta = p1-p0;
    ad = abs(delta);
    s = sign(delta);
    n = max(ad);
    guardSize(n);
    points = zeros(n+1,2);
    points(1,:) = p0;
    p = p0;
    acc = [0 0];
    for k = 1:n
        acc = acc+ad;
        for j = 1:2
            if acc(j)>=n
                p(j) = p(j)+s(j);
                acc(j) = acc(j)-n;
            end
        end
        points(k+1,:) = p;
    end
end

function points = circularPBC(p0,p1,c,s,sweep)
% One-axis-per-pulse: candidates point along the signed tangent.
% Select the next step with the smallest absolute radial decision error.
% Track unwrapped angular progress to prevent passing the requested endpoint.
    r2 = sum((p0-c).^2);
    radius = sqrt(r2);
    maxIter = ceil(12*radius*sweep)+100;
    guardSize(maxIter);
    points = zeros(maxIter+1,2);
    points(1,:) = p0;
    p = p0;
    phase = 0;
    n = 1;
    for iter = 1:maxIter
        if n>1 && isequal(p,p1)
            points = points(1:n,:);
            return;
        end
        relative = p-c;
        tangent = s*[-relative(2), relative(1)];
        candidates = zeros(2,2);
        scores = inf(2,2);
        phases = zeros(2,1);
        numCandidates = 0;
        theta = atan2(relative(2),relative(1));
        for axis = 1:2
            if tangent(axis)==0, continue; end
            proposed = p;
            proposed(axis) = proposed(axis)+sign(tangent(axis));
            nextTheta = atan2(proposed(2)-c(2),proposed(1)-c(1));
            dtheta = mod(s*(nextTheta-theta),2*pi);
            nextPhase = phase+dtheta;
            if dtheta<=1e-12 || dtheta>=pi/2 || nextPhase>sweep+1e-8
                continue;
            end
            numCandidates = numCandidates+1;
            candidates(numCandidates,:) = proposed;
            phases(numCandidates) = nextPhase;
            radialError = abs(sum((proposed-c).^2)-r2);
            distanceToEnd = norm(proposed-p1);
            scores(numCandidates,:) = [radialError,distanceToEnd];
        end
        if numCandidates==0
            error('Interpolation:Stall','Circular comparator stalled: check arc geometry.');
        end
        [~,ranking] = sortrows(scores(1:numCandidates,:),[1 2]);
        winner = ranking(1);
        p = candidates(winner,:);
        phase = phases(winner);
        n = n+1;
        points(n,:) = p;
    end
    error('Interpolation:IterationLimit','Circular comparator exceeded iteration limit.');
end

function points = circularDDA(p0,p1,c,s,sweep)
% Cross-coupled differential accumulators:
% dx/dtheta = -s*y,  dy/dtheta = s*x.
% The normalized Euler increment is a pure rotation. Choosing h=tan(dtheta)
% makes the per-tick phase dtheta exact while avoiding accumulated drift.
% Grid pulses are emitted when either real-valued accumulator rounds over.
    r = norm(p0-c);
    nTicks = max(1,ceil(max(3*r*sweep, 4*sweep/pi)));
    guardSize(nTicks);
    dtheta = sweep/nTicks;
    h = tan(dtheta);
    scale = 1/sqrt(1+h*h);
    realXY = p0-c;
    points = zeros(nTicks+2,2);
    points(1,:) = p0;
    n = 1;
    for k = 1:nTicks
        old = realXY;
        realXY = scale*[old(1)-s*h*old(2), old(2)+s*h*old(1)];
        q = round(c+realXY);
        if ~isequal(q,points(n,:))
            n=n+1;
            points(n,:) = q;
        end
    end
    if ~isequal(points(n,:),p1)
        n=n+1;
        points(n,:)=p1; % exact, validated integer-grid endpoint
    end
    points = points(1:n,:);
end

function guardSize(n)
    if n>50000
        error('Interpolation:TooLong', ...
           'Path exceeds 50,000 interpolation cycles. Reduce coordinates/radius.');
    end
end
