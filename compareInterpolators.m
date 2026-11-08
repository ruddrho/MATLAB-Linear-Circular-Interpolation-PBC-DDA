function comparison = compareInterpolators(pathType,startXY,endXY,centerXY,direction)
%COMPAREINTERPOLATORS Run PBC and DDA for identical geometric parameters.
%  Algorithm timings are illustrative CPU measurements, not machine timing.
    methods = {'Point-by-Point Comparison','DDA'};
    result = cell(1,2); elapsedMs = zeros(1,2);
    for k=1:2
        startTime = tic;
        result{k} = interpolatePath(pathType,methods{k}, ...
            startXY,endXY,centerXY,direction);
        elapsedMs(k) = toc(startTime)*1000;
    end
    n = 2;
    pulseCycles = zeros(n,1); maxError = zeros(n,1);
    meanError = zeros(n,1); endpointError = zeros(n,1);
    pathLength = zeros(n,1);
    for k=1:n
        r = result{k};
        pulseCycles(k) = r.info.PulseCycles;
        maxError(k) = r.info.MaxDeviation;
        meanError(k) = mean(r.deviation);
        endpointError(k) = norm(double(r.points(end,:))-double(endXY));
        pathLength(k) = r.info.PathLength;
    end
    comparison.PBC = result{1};
    comparison.DDA = result{2};
    comparison.TimingMs = elapsedMs;
    comparison.Metrics = table(methods',pulseCycles,maxError,meanError, ...
        endpointError,pathLength,elapsedMs', ...
        'VariableNames',{'Method','PulseCycles','MaxDeviation', ...
                         'MeanDeviation','EndpointError','PathLength', ...
                         'CPUTimeMs'});
end
