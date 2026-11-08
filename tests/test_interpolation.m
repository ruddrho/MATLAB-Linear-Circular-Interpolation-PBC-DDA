function test_interpolation()
%TEST_INTERPOLATION Self-contained algorithm regression tests (no toolboxes).
% From project root: addpath('tests'); test_interpolation
    methods = {'Point-by-Point Comparison','DDA'};
    lineCases = { [0 0],[10 7]; [10 7],[-2 4]; ...
                  [-5 8],[7 -4]; [1 2],[1 -9]; ...
                  [1 2],[-7 2]; [3 3],[3 3] };
    tests = 0;
    for m = 1:numel(methods)
        for k = 1:size(lineCases,1)
            a = lineCases{k,1}; b = lineCases{k,2};
            r = interpolatePath('Linear',methods{m},a,b,[0 0],'CCW');
            assert(isequal(r.points(1,:),a));
            assert(isequal(r.points(end,:),b));
            d = diff(r.points,1,1); % Successive XY rows, even for a single-point path.
            assert(all(abs(d(:))<=1));
            if strcmp(methods{m},'Point-by-Point Comparison')
                assert(all(sum(abs(d),2)==1));
                assert(size(r.points,1)==sum(abs(b-a))+1);
            else
                assert(size(r.points,1)==max(abs(b-a))+1);
            end
            assert(r.info.MaxDeviation<=1);
            assert(r.info.PulseCycles == size(r.points,1)-1);
            if isequal(a,b)
                assert(isequal(size(r.points),[1 2]));
                assert(isequal(size(d),[0 2]));
                assert(r.info.PulseCycles==0);
                assert(r.info.PathLength==0);
            end
            tests = tests+1;
        end
    end

    circlePoints = [12 0;0 12;-12 0;0 -12;5 12;-5 12;-12 -5;12 -5];
    for m = 1:numel(methods)
        for signValue = {'CW','CCW'}
            for k = 1:size(circlePoints,1)
                a = circlePoints(k,:);
                % Pick matching-radius end point using 90 degree rotation.
                b = [-a(2),a(1)];
                r = interpolatePath('Circular',methods{m},a,b, ...
                    [0 0],signValue{1});
                assert(isequal(r.points(1,:),a));
                assert(isequal(r.points(end,:),b));
                d = diff(r.points,1,1); % Successive XY rows (never across X/Y).
                assert(all(abs(d(:))<=1));
                assert(r.info.MaxDeviation<=1.1);
                if strcmp(methods{m},'Point-by-Point Comparison')
                    assert(all(sum(abs(d),2)==1));
                end
                tests = tests+1;
            end
            r = interpolatePath('Circular',methods{m}, ...
                [9 0],[9 0],[0 0],signValue{1});
            assert(isequal(r.points(1,:),r.points(end,:)));
            assert(r.info.PulseCycles>10);
            tests = tests+1;
        end
    end
    try
        interpolatePath('Circular','DDA',[10 0],[0 9],[0 0],'CCW');
        error('Test:ExpectedError','Expected unequal-radius input rejection.');
    catch e
        assert(strcmp(e.identifier,'Interpolation:ArcRadius'));
    end
    fprintf('PASS: %d interpolation tests plus invalid-radius check.\n',tests);
end
