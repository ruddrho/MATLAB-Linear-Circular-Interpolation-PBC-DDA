function test_dda_registers()
% TEST_DDA_REGISTERS Check the blackboard's 3-bit X/Y pulse example.
% From project root: addpath('tests'); test_dda_registers
    r = ddaRegisterTrace('101','000','011','000',3,8);
    assert(r.NBits == 3 && r.Cycles == 8);
    assert(height(r.Table)==9,'Includes the initial row (clock 0).');
    assert(r.PulseX==5 && r.PulseY==3);
    assert(isequal(r.Points(end,:),[5 3]));
    assert(isequal(r.Table.Step,(0:8)'));
    assert(isequal(r.Table.J_rx, ...
        {'000';'101';'010';'111';'100';'001';'110';'011';'000'}));
    assert(isequal(r.Table.J_ry, ...
        {'000';'011';'110';'001';'100';'111';'010';'101';'000'}));
    assert(isequal(r.Table.PulseX,[0;0;1;0;1;1;0;1;1]));
    assert(isequal(r.Table.PulseY,[0;0;0;1;0;0;1;0;1]));

    % A deliberately nonzero initial remainder must affect the first carry.
    shifted = ddaRegisterTrace('101','100','011','110',3,1);
    assert(shifted.Table.PulseX(2)==1 && shifted.Table.PulseY(2)==1);
    assert(strcmp(shifted.Table.J_rx{2},'001'));
    assert(strcmp(shifted.Table.J_ry{2},'001'));

    root = fileparts(fileparts(mfilename('fullpath')));
    config = readDDARegisters(fullfile(root,'examples', ...
        'dda_registers_example.csv'));
    assert(strcmp(config.J_vx,'101'));
    assert(strcmp(config.J_rx,'000'));
    assert(strcmp(config.J_vy,'011'));
    assert(strcmp(config.J_ry,'000'));
    assert(config.NBits==3 && config.Cycles==8);

    configText = readDDARegisters(fullfile(root,'examples', ...
        'dda_registers_key_value.txt'));
    assert(isequal(config,configText));

    try
        ddaRegisterTrace('102','000','011','000',3,8);
        error('Test:ExpectedError','Invalid binary digits must fail.');
    catch e
        assert(strcmp(e.identifier,'DDA:InvalidBinary'));
    end
    try
        ddaRegisterTrace('1010','000','011','000',3,8);
        error('Test:ExpectedError','Over-width register must fail.');
    catch e
        assert(strcmp(e.identifier,'DDA:RegisterOverflow'));
    end
    fprintf('PASS: DDA register overflow sequence, imports and validation.\n');
end
