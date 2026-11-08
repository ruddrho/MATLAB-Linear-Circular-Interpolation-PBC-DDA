function test_ui_defaults_source()
%TEST_UI_DEFAULTS_SOURCE Check high-contrast ticks and zero-value startup.
% This headless source test does not require a graphical desktop.
    root=fileparts(fileparts(mfilename('fullpath')));
    pro=fileread(fullfile(root,'CNCProfessionalDashboard.m'));
    classic=fileread(fullfile(root,'CNCInterpolationApp.m'));

    for name={'X0','Y0','X1','Y1','CX','CY'}
        expression=['app.',name{1},'=app.number(f,0);'];
        assert(contains(pro,expression), ...
            ['Professional default must be 0: ',name{1}]);
    end
    for name={'X0','Y0','X1','Y1','CX','CY'}
        expression=['app.',name{1},'Field = app.makeNumber(parent,0,'];
        assert(contains(classic,expression), ...
            ['Classic default must be 0: ',name{1}]);
    end
    assert(contains(pro,'tickText={''0'',''0.25'',''0.50'',''0.75'',''1.00''}'));
    assert(contains(pro,'sliderArea=uigridlayout(mg,[4 1])'));
    assert(contains(pro,'ANIMATION DELAY (SECONDS / STEP)'));
    assert(contains(pro,'Fresh sessions start with all geometry fields at zero'));
    fprintf('PASS: zero-value UI defaults and high-contrast slider labeling.\n');
end
