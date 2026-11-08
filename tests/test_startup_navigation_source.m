function test_startup_navigation_source()
%TEST_STARTUP_NAVIGATION_SOURCE Headless check for Classic-first launch.
    root=fileparts(fileparts(mfilename('fullpath')));
    launcher=fileread(fullfile(root,'run_app.m'));
    classic=fileread(fullfile(root,'CNCInterpolationApp.m'));
    pro=fileread(fullfile(root,'CNCProfessionalDashboard.m'));
    assert(contains(launcher,"view = 'classic'"));
    assert(contains(launcher,'app = CNCInterpolationApp();'));
    assert(contains(launcher,'app = CNCProfessionalDashboard();'));
    assert(contains(classic,"'Text','Open PRO View'"));
    assert(contains(classic,'app.HeaderPanel = uipanel(app.UIFigure, ...'));
    assert(contains(classic,'app.HeaderBar = uigridlayout(app.HeaderPanel,[1 3]);'));
    assert(~contains(classic,'app.HeaderBar.Position ='));
    assert(contains(classic,"'Text','CNC INTERPOLATION STUDIO PRO'"));
    assert(contains(classic,'app.ProViewButton.Layout.Column = 3;'));
    assert(~contains(classic,"'Text','OPEN PRO VIEW  >>'"));
    assert(contains(classic,'function openProfessional(app)'));
    assert(contains(classic,'CNCProfessionalDashboard(app)'));
    assert(contains(pro,'function openClassic(app)'));
    assert(contains(pro,'CNCInterpolationApp(app)'));
    fprintf('PASS: Classic-first launcher and bidirectional PRO navigation.\n');
end
