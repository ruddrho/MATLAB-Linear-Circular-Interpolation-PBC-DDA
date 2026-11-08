function test_pdf_export()
%TEST_PDF_EXPORT Optional figure-based PDF smoke test on graphical MATLAB.
% May be skipped on CI systems without graphical printing support.
    p=struct('PathType','Linear','Direction','CCW', ...
        'Start',[0 0],'End',[12 7],'Center',[0 0]);
    cmp=compareInterpolators(p.PathType,p.Start,p.End,p.Center,p.Direction);
    file=[tempname,'.pdf'];
    cleanup=onCleanup(@()deleteIfPresent(file)); %#ok<NASGU>
    exportCNCReport(file,cmp,p);
    assert(isfile(file));
    meta=dir(file);assert(meta.bytes>1000);
    fprintf('PASS: PDF export.\n');
end
function deleteIfPresent(file)
    if isfile(file),delete(file);end
end
