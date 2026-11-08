function logTable = buildStepLog(result,startXY,endXY,centerXY)
%BUILDSTEPLOG Per-step displacement, decision variable and geometry error.
%  Linear PBC: decision = dx_along*abs(dy)-dy_along*abs(dx).
%  Circular: decision = (x-Cx)^2+(y-Cy)^2-R^2.
%  Linear DDA: decision shows pre-step X accumulator (modulo max delta).
    p = result.points;
    n = size(p,1);
    dx = [0; diff(p(:,1))];
    dy = [0; diff(p(:,2))];
    decision = zeros(n,1);
    if strcmp(result.info.PathType,'Linear')
        delta = endXY-startXY;
        ad = abs(delta);
        signs = sign(delta);
        if strcmp(result.info.Method,'Point-by-Point Comparison')
            for k=2:n
                prev = p(k-1,:)-startXY;
                along = prev.*signs;
                decision(k) = along(1)*ad(2)-along(2)*ad(1);
            end
        else
            ticks = max(ad);
            if ticks>0
                decision(:) = mod((0:n-1)'*ad(1),ticks);
            end
        end
    else
        r2 = sum((startXY-centerXY).^2);
        decision = sum((p-centerXY).^2,2)-r2;
    end
    logTable = table((0:n-1)',p(:,1),p(:,2),dx,dy,decision, ...
        result.deviation,'VariableNames', ...
        {'Step','X','Y','dX','dY','Decision','Deviation'});
end
