function run_tests(withPDF)
%RUN_TESTS Run headless algorithm tests; optionally test PDF rendering.
%   run_tests        % avoids requiring a graphical printer
%   run_tests(true)  % includes A4 report smoke test
    if nargin<1,withPDF=false;end
    root=fileparts(mfilename('fullpath'));
    addpath(root,fullfile(root,'tests'));
    test_interpolation();
    test_dda_registers();
    test_professional_algorithms();
    test_waypoint_import();
    test_pro_source();
    test_ui_defaults_source();
    test_startup_navigation_source();
    test_classic_header_source();
    test_header_layout_position_source();
    test_origin_axes_source();
    if withPDF,test_pdf_export();end
    fprintf('All selected CNC Interpolation Studio PRO tests passed.\n');
end
