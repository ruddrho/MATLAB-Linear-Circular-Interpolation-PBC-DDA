function test_classic_header_source()
%TEST_CLASSIC_HEADER_SOURCE Ensure Classic matches PRO header/navigation.
    root=fileparts(fileparts(mfilename('fullpath')));
    classic=fileread(fullfile(root,'CNCInterpolationApp.m'));
    pro=fileread(fullfile(root,'CNCProfessionalDashboard.m'));
    assert(contains(classic,'app.HeaderPanel = uipanel(app.UIFigure, ...'));
    assert(contains(classic,'app.HeaderBar = uigridlayout(app.HeaderPanel,[1 3]);'));
    assert(~contains(classic,'app.HeaderBar.Position ='));
    assert(contains(classic,"'Text','CNC INTERPOLATION STUDIO PRO'"));
    assert(contains(pro,'CNC INTERPOLATION STUDIO PRO'));
    assert(contains(classic,'PBC / DDA  •  2D Toolpaths  •  Register Lab  •  G-code  •  Reports'));
    assert(contains(classic,"'Text','Open PRO View'"));
    assert(contains(pro,"'Text','Open Classic View'"));
    assert(contains(classic,'app.ProViewButton.Layout.Column = 3;'));
    assert(contains(classic,'app.ProViewButton.ButtonPushedFcn = @(~,~)app.openProfessional();'));
    assert(~contains(classic,'uibutton(app.ResultsPanel')));
    fprintf('PASS: Classic header layout and PRO navigation source.\n');
end
