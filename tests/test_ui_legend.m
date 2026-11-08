function test_ui_legend()
%TEST_UI_LEGEND MATLAB UI smoke test for the reference-style legend.
% Run from the project root: addpath('tests'); test_ui_legend
% Requires a MATLAB installation supporting uifigure/AppBase.
    app = CNCInterpolationApp();
    cleanUp = onCleanup(@()delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';

    keys = {'Command path','Interpolated path','Start S', ...
            'End E','Center C','Current point'};
    labels = app.LegendPanel.Children;
    displayed = cell(1,numel(labels));
    for k = 1:numel(labels)
        displayed{k} = char(labels(k).Text);
    end
    for k = 1:numel(keys)
        assert(any(strcmp(displayed,keys{k})), ...
            ['Legend item not found: ',keys{k}]);
    end

    % Public repository build does not expose personal identity inputs.
    assert(~isprop(app,'StudentNameField'));
    assert(~isprop(app,'StudentIDField'));

    app.ModeDropDown.Value = 'Linear';
    app.MethodDropDown.Value = 'DDA';
    app.X0Field.Value = 0;
    app.Y0Field.Value = 0;
    app.X1Field.Value = 4;
    app.Y1Field.Value = 3;
    app.ComputeButton.ButtonPushedFcn([],[]);
    pathTable = app.OutputTable.Data;
    assert(height(pathTable)==5,'DDA 4x3 test should have 5 samples.');
    % Locate the publicly visible graphical marker instead of attempting
    % to access a private AppBase property from the test function.
    marker = findobj(app.PlotAxes,'Type','Line', ...
        'Marker','o','MarkerSize',10);
    assert(isscalar(marker),'Exactly one current-point marker expected.');
    assert(marker.XData==pathTable.X(1));
    assert(marker.YData==pathTable.Y(1));

    app.StepButton.ButtonPushedFcn([],[]);
    assert(marker.XData==pathTable.X(2));
    assert(marker.YData==pathTable.Y(2));

    app.ResetButton.ButtonPushedFcn([],[]);
    assert(marker.XData==pathTable.X(1));
    assert(marker.YData==pathTable.Y(1));

    fprintf('PASS: six legend keys, identity-free UI and playback/reset.\n');
end
