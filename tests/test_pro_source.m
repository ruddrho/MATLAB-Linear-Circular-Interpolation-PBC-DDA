function test_pro_source()
%TEST_PRO_SOURCE Dependency / integration smoke test (without opening GUI).
    root=fileparts(fileparts(mfilename('fullpath')));
    source=fileread(fullfile(root,'CNCProfessionalDashboard.m'));
    assert(contains(source,'classdef CNCProfessionalDashboard < matlab.apps.AppBase'));
    for name={'makeSimulationTab','makeComparisonTab','makeErrorTab', ...
              'makeRegisterTab','makeGcodeTab','makeExportTab', ...
              'saveProject','loadProject','exportReport','openClassic'}
        assert(contains(source,name{1}));
    end
    assert(~contains(source,'StudentName'));
    assert(~contains(source,'StudentID'));
    fprintf('PASS: professional app source integration checks.\n');
end
