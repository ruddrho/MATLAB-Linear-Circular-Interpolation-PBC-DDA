function test_header_layout_position_source()
%TEST_HEADER_LAYOUT_POSITION_SOURCE Avoid assigning to read-only Position.
    root = fileparts(fileparts(mfilename('fullpath')));
    classic = fileread(fullfile(root,'CNCInterpolationApp.m'));
    assert(contains(classic,'app.HeaderPanel = uipanel(app.UIFigure, ...'));
    assert(contains(classic,"'Position',[18 754 1280 44]"));
    assert(contains(classic,'app.HeaderBar = uigridlayout(app.HeaderPanel,[1 3]);'));
    assert(~contains(classic,'app.HeaderBar.Position ='));
    assert(contains(classic,"'Text','Open PRO View'"));
    fprintf('PASS: Classic header uses positioned panel with nested GridLayout.\n');
end
