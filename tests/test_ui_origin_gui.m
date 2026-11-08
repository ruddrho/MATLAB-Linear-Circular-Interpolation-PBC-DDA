function test_ui_origin_gui()
%TEST_UI_ORIGIN_GUI Optional desktop MATLAB GUI smoke test.
%   addpath('tests'); test_ui_origin_gui
    pro=CNCProfessionalDashboard();
    cleanupPro=onCleanup(@()delete(pro)); %#ok<NASGU>
    pro.UIFigure.Visible='off';
    classic=CNCInterpolationApp();
    cleanupClassic=onCleanup(@()delete(classic)); %#ok<NASGU>
    classic.UIFigure.Visible='off';
    assertOrigin(pro.SimAxes);
    assertOrigin(pro.PBCPlot);
    assertOrigin(pro.DDAPlot);
    assertOrigin(pro.RegisterAxes);
    assertOrigin(pro.GCodeAxes);
    assertOrigin(classic.PlotAxes);

    % A positive-quadrant path must retain X=0 and Y=0 at the center.
    classic.ModeDropDown.Value='Linear';
    classic.X0Field.Value=0;classic.Y0Field.Value=0;
    classic.X1Field.Value=40;classic.Y1Field.Value=30;
    classic.ComputeButton.ButtonPushedFcn([],[]);
    assertOrigin(classic.PlotAxes);
    pro.PathType.Value='Linear';
    pro.X1.Value=40;pro.Y1.Value=30;
    pro.Method.Value='DDA';
    generateButton=findall(pro.UIFigure,'Text','Generate Path');
    assert(~isempty(generateButton));
    generateButton(1).ButtonPushedFcn([],[]);
    assertOrigin(pro.SimAxes);
    fprintf('PASS: visible origin in dashboard and Classic View.\n');
end
function assertOrigin(ax)
    limits=ax.XLim;assert(abs(limits(1)+limits(2))<1e-8);
    limits=ax.YLim;assert(abs(limits(1)+limits(2))<1e-8);
    assert(numel(findall(ax,'Tag','CNCZeroXAxis'))==1);
    assert(numel(findall(ax,'Tag','CNCZeroYAxis'))==1);
    assert(numel(findall(ax,'Tag','CNCOriginLabel'))==1);
end
