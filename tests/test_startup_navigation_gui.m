function test_startup_navigation_gui()
%TEST_STARTUP_NAVIGATION_GUI Optional GUI test on graphical MATLAB.
    classic=run_app();
    cleanup=onCleanup(@()delete(classic)); %#ok<NASGU>
    classic.UIFigure.Visible='off';
    assert(isa(classic,'CNCInterpolationApp'));
    assert(strcmp(classic.ModeDropDown.Value,'Linear'));
    assert(strcmp(classic.MethodDropDown.Value,'Point-by-Point Comparison'));
    assert(all([classic.X0Field.Value classic.Y0Field.Value ...
               classic.X1Field.Value classic.Y1Field.Value ...
               classic.CXField.Value classic.CYField.Value] == 0));
    assert(isvalid(classic.ProViewButton));
    assert(isequal(classic.ProViewButton.Parent,classic.HeaderBar));
    assert(isequal(classic.HeaderBar.Parent,classic.HeaderPanel));
    assert(isequal(classic.HeaderPanel.Position,[18 754 1280 44]));
    assert(strcmp(classic.ProViewButton.Text,'Open PRO View'));
    assert(classic.ProViewButton.Layout.Column==3);
    assert(isequal(classic.HeaderBar.ColumnWidth{3},190));
    classic.ProViewButton.ButtonPushedFcn([],[]);
    proWindow=findall(groot,'Type','figure','Name','CNC Interpolation Studio PRO');
    assert(numel(proWindow)==1);
    classic.ProViewButton.ButtonPushedFcn([],[]);
    proWindow=findall(groot,'Type','figure','Name','CNC Interpolation Studio PRO');
    assert(numel(proWindow)==1, 'Repeated PRO clicks must reuse the window.');
    delete(proWindow);
    fprintf('PASS: Classic-first launch and PRO navigation.\n');
end
