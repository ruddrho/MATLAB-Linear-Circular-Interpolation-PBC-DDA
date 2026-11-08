function test_professional_algorithms()
%TEST_PROFESSIONAL_ALGORITHMS Headless tests for comparison/step/G-code logic.
    for type={'Linear','Circular'}
        if strcmp(type{1},'Circular')
            a=[12 0];b=[0 12];c=[0 0];
        else
            a=[-4 6];b=[7 -2];c=[0 0];
        end
        cmp=compareInterpolators(type{1},a,b,c,'CCW');
        assert(height(cmp.Metrics)==2);
        assert(all(cmp.Metrics.EndpointError==0));
        assert(all(cmp.Metrics.MaxDeviation>=0));
        assert(all(cmp.Metrics.PulseCycles>=0));
        assert(isequal(cmp.PBC.points(1,:),a));
        assert(isequal(cmp.DDA.points(end,:),b));
        for method={'PBC','DDA'}
            r=cmp.(method{1});
            trace=buildStepLog(r,a,b,c);
            assert(height(trace)==size(r.points,1));
            assert(all(diff(trace.X)==trace.dX(2:end)));
            assert(all(diff(trace.Y)==trace.dY(2:end)));
            assert(max(abs(trace.Deviation-r.deviation))<1e-10);
        end
    end
    demo=sprintf('G90\nG00 X0 Y0\nG01 X12 Y0\nG03 X0 Y12 I-12 J0\nG01 X0 Y0\n');
    p=parseCNCGCode(demo,'DDA');
    assert(p.MotionSegments==4);
    assert(p.RapidSegments==1);
    assert(isequal(p.EndPosition,[0 0]));
    assert(size(p.Points,2)==2);
    assert(isequal(p.Segments(3).Start,[12 0]));
    assert(isequal(p.Segments(3).End,[0 12]));
    relative=sprintf('G91\nG01 X5 Y3\nG01 X-5 Y-3\n');
    q=parseCNCGCode(relative,'Point-by-Point Comparison');
    assert(isequal(q.EndPosition,[0 0]));
    assert(isequal(q.Segments(1).End,[5 3]));
    assert(isequal(q.Segments(2).End,[0 0]));
    bad=sprintf('G90\nG00 X12 Y0\nG03 X0 Y11 I-12 J0\n');
    try
        parseCNCGCode(bad,'DDA');
        error('Test:MissingFailure','Expected arc mismatch error.');
    catch err
        assert(strcmp(err.identifier,'Interpolation:ArcRadius'));
    end
    try
        parseCNCGCode('G28 X0 Y0','DDA');
        error('Test:MissingFailure','Expected unsupported code.');
    catch err
        assert(strcmp(err.identifier,'GCode:Unsupported'));
    end
    fprintf('PASS: Professional comparison, step log, G-code and validation tests.\n');
end
