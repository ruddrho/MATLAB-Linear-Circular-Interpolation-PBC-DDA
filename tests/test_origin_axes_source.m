function test_origin_axes_source()
%TEST_ORIGIN_AXES_SOURCE Headless contract checks for Cartesian origin.
    root=fileparts(fileparts(mfilename('fullpath')));
    h=fileread(fullfile(root,'drawCNCXYOrigin.m'));
    c=fileread(fullfile(root,'CNCInterpolationApp.m'));
    p=fileread(fullfile(root,'CNCProfessionalDashboard.m'));
    assert(contains(h,"xlim(ax,[-extent(1) extent(1)])"));
    assert(contains(h,"ylim(ax,[-extent(2) extent(2)])"));
    for tag={'CNCZeroXAxis','CNCZeroYAxis','CNCOriginLabel', ...
             'CNCDirectionX','CNCDirectionY'}
        assert(contains(h,tag{1}),['Missing origin annotation: ',tag{1}]);
    end
    assert(contains(c,'drawCNCXYOrigin(app.PlotAxes,[])'));
    assert(contains(c,'drawCNCXYOrigin(ax,viewPoints)'));
    assert(contains(p,'xyViews={app.SimAxes,app.PBCPlot,app.DDAPlot'));
    assert(contains(p,'drawCNCXYOrigin(ax,p)'));
    fprintf('PASS: zero-centered Cartesian origin on all XY views.\n');
end
