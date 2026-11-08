function test_ui_defaults_gui()
%TEST_UI_DEFAULTS_GUI Optional graphical smoke test on a MATLAB desktop.
    pro=CNCProfessionalDashboard();
    cleaner=onCleanup(@()delete(pro)); %#ok<NASGU>
    pro.UIFigure.Visible='off';
    assert(strcmp(pro.PathType.Value,'Linear'));
    assert(strcmp(pro.Method.Value,'Point-by-Point Comparison'));
    assert(strcmp(pro.CX.Enable,'off') && strcmp(pro.CY.Enable,'off'));
    assert(strcmp(pro.Direction.Enable,'off'));
    assert(all([pro.X0.Value pro.Y0.Value pro.X1.Value ...
                pro.Y1.Value pro.CX.Value pro.CY.Value]==0));
    assert(isempty(pro.SimTable.Data));
    assert(strcmp(pro.SpeedSlider.MajorTickLabels{1},''));
    pro.SpeedSlider.Value=0.25;
    pro.SpeedSlider.ValueChangedFcn([],[]);
    assert(abs(pro.Delay.Value-0.25)<1e-12);
    pro.Delay.Value=0.50;
    pro.Delay.ValueChangedFcn([],[]);
    assert(abs(pro.SpeedSlider.Value-0.50)<1e-12);
    classic=CNCInterpolationApp();
    cleaner2=onCleanup(@()delete(classic)); %#ok<NASGU>
    classic.UIFigure.Visible='off';
    assert(strcmp(classic.ModeDropDown.Value,'Linear'));
    assert(strcmp(classic.MethodDropDown.Value,'Point-by-Point Comparison'));
    assert(all([classic.X0Field.Value classic.Y0Field.Value ...
                classic.X1Field.Value classic.Y1Field.Value ...
                classic.CXField.Value classic.CYField.Value]==0));
    fprintf('PASS: UI defaults, animation slider synchronization, no startup error.\n');
end
