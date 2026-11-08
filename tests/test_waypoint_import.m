function test_waypoint_import()
%TEST_WAYPOINT_IMPORT Tests CSV geometry import and malformed input handling.
    example=fullfile(fileparts(mfilename('fullpath')),'..','examples', ...
        'waypoints_circular.csv');
    p=readCNCWaypoints(example);
    assert(isequal(p.Start,[12 0]));
    assert(isequal(p.End,[0 12]));
    assert(isequal(p.Center,[0 0]));
    result=interpolatePath('Circular','DDA',p.Start,p.End,p.Center,'CCW');
    assert(isequal(result.points(end,:),p.End));
    fprintf('PASS: waypoint CSV import.\n');
end
