function drawCNCXYOrigin(ax,points)
%DRAWCNCXYORIGIN Center a Cartesian XY plot on the true (0,0) origin.
%   drawCNCXYOrigin(ax,points) draws X=0 and Y=0 reference axes,
%   a readable zero label, and positive X/Y directions behind a toolpath.
%   The viewport stays symmetric about zero even for one-quadrant paths.
%
    if nargin<2 || isempty(points)
        points=zeros(0,2);
    end
    if ~isnumeric(points) || size(points,2)~=2 || ...
            any(~isfinite(points(:)))
        error('CNCOrigin:Points','Points must be finite numeric Nx2 coordinates.');
    end

    % Avoid stacking overlays when the view is refreshed without cla.
    tags={'CNCZeroXAxis','CNCZeroYAxis','CNCOriginLabel', ...
          'CNCDirectionX','CNCDirectionY'};
    for k=1:numel(tags)
        old=findall(ax,'Tag',tags{k});
        if ~isempty(old), delete(old); end
    end

    if isempty(points)
        extent=[10 10];
    else
        extent=max(abs(points),[],1);
        extent=max(5,extent*1.16);
    end
    xlim(ax,[-extent(1) extent(1)]);
    ylim(ax,[-extent(2) extent(2)]);
    axis(ax,'equal');
    grid(ax,'on');

    previousHold=ishold(ax);
    hold(ax,'on');
    % Match the axis/reference annotation to the current dark/light theme.
    fg=ax.XColor;
    line(ax,[-extent(1) extent(1)],[0 0],'Color',fg, ...
        'LineWidth',1.45,'HandleVisibility','off', ...
        'Tag','CNCZeroXAxis','HitTest','off');
    line(ax,[0 0],[-extent(2) extent(2)],'Color',fg, ...
        'LineWidth',1.45,'HandleVisibility','off', ...
        'Tag','CNCZeroYAxis','HitTest','off');
    % Offset the zero annotation so it does not cover the start marker.
    text(ax,0.045*extent(1),-0.09*extent(2),'0', ...
        'Color',fg,'FontWeight','bold','FontSize',11, ...
        'HorizontalAlignment','left','VerticalAlignment','top', ...
        'HandleVisibility','off','Tag','CNCOriginLabel', ...
        'HitTest','off');
    text(ax,0.87*extent(1),0.085*extent(2),'X', ...
        'Color',fg,'FontWeight','bold','FontSize',11, ...
        'HandleVisibility','off','Tag','CNCDirectionX', ...
        'HitTest','off');
    text(ax,0.075*extent(1),0.87*extent(2),'Y', ...
        'Color',fg,'FontWeight','bold','FontSize',11, ...
        'HandleVisibility','off','Tag','CNCDirectionY', ...
        'HitTest','off');
    if ~previousHold,hold(ax,'off');end
end
