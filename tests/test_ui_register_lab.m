function test_ui_register_lab()
% TEST_UI_REGISTER_LAB UI smoke test; requires MATLAB desktop display.
    app = CNCInterpolationApp();
    cleanUp = onCleanup(@()delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';
    assert(~isprop(app,'StudentNameField'));
    app.RegisterButton.ButtonPushedFcn([],[]);
    app.DDALabFigure.Visible = 'off';
    assert(strcmp(app.RegisterVXField.Value,'101'));
    assert(strcmp(app.RegisterRXField.Value,'000'));
    assert(strcmp(app.RegisterVYField.Value,'011'));
    assert(strcmp(app.RegisterRYField.Value,'000'));
    assert(height(app.RegisterTable.Data)==9);
    assert(isequal([app.RegisterTable.Data.X(end), ...
                    app.RegisterTable.Data.Y(end)],[5 3]));
    app.RegisterStepButton.ButtonPushedFcn([],[]);
    assert(contains(app.RegisterStatusLabel.Text,'Clock 1 / 8'));
    app.RegisterComputeButton.ButtonPushedFcn([],[]);
    assert(contains(app.RegisterStatusLabel.Text,'Generated 8 clocks'));
    fprintf('PASS: DDA register popup, default fields and step button.\n');
end
