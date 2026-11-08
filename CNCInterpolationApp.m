classdef CNCInterpolationApp < matlab.apps.AppBase
    % CNCINTERPOLATIONAPP Programmatic MATLAB App Designer-style UI.
    % Run by entering CNCInterpolationApp in the MATLAB Command Window.
    % This .m AppBase class is source-editable; it is not a .mlapp binary.

    properties (Access = public)
        UIFigure
        HeaderPanel
        HeaderBar
        ControlPanel
        PlotAxes
        ResultsPanel
        ProViewButton
        OutputTable
        ModeDropDown
        MethodDropDown
        DirectionDropDown
        X0Field
        Y0Field
        X1Field
        Y1Field
        CXField
        CYField
        DelayField
        ComputeButton
        StepButton
        AnimateButton
        PauseButton
        ResetButton
        ExportButton
        PulseLabel
        LengthLabel
        ErrorLabel
        SweepLabel
        StatusLabel
        LegendPanel
        RegisterButton
        DDALabFigure
        RegisterVXField
        RegisterRXField
        RegisterVYField
        RegisterRYField
        RegisterBitsField
        RegisterCyclesField
        RegisterImportButton
        RegisterComputeButton
        RegisterStepButton
        RegisterExportButton
        RegisterTable
        RegisterAxes
        RegisterStatusLabel
    end

    properties (Access = private)
        Result = []
        LiveLine = []
        CurrentMarker = []
        Cursor = 1
        IsPlaying = false
        RegisterResult = []
        RegisterCursor = 1
        RegisterLiveLine = []
        RegisterCurrentPoint = []
        ProfessionalApp = []
    end

    methods (Access = private)
        function createComponents(app)
            navy = [0.075 0.105 0.16];
            panel = [0.11 0.155 0.225];
            light = [0.91 0.96 1.0];
            teal = [0.20 0.86 0.76];

            app.UIFigure = uifigure('Name','CNC Interpolation Studio | MATLAB', ...
                'Position',[100 80 1320 800], 'Color',navy);
            app.UIFigure.CloseRequestFcn = @(~,~)delete(app);
            % The Classic home screen uses the same three-column header as
            % the Professional Dashboard: identity, module summary, navigation.
            % Its fixed location stays above (not inside) the content panels.
            % A GridLayout's Position property is read-only in MATLAB.
            % Put the 3-column layout inside a positioned panel instead.
            app.HeaderPanel = uipanel(app.UIFigure, ...
                'BorderType','none', ...
                'Position',[18 754 1280 44], ...
                'BackgroundColor',navy);
            app.HeaderBar = uigridlayout(app.HeaderPanel,[1 3]);
            app.HeaderBar.RowHeight = {'1x'};
            app.HeaderBar.ColumnWidth = {'2x','3x',190};
            app.HeaderBar.ColumnSpacing = 9;
            app.HeaderBar.RowSpacing = 0;
            app.HeaderBar.Padding = [5 0 5 0];
            app.HeaderBar.BackgroundColor = navy;

            headerTitle = uilabel(app.HeaderBar, ...
                'Text','CNC INTERPOLATION STUDIO PRO', ...
                'FontName','Arial','FontSize',20,'FontWeight','bold', ...
                'FontColor',light);
            headerTitle.Layout.Column = 1;
            headerTitle.HorizontalAlignment = 'left';

            headerSubtitle = uilabel(app.HeaderBar, ...
                'Text','PBC / DDA  •  2D Toolpaths  •  Register Lab  •  G-code  •  Reports', ...
                'FontSize',12,'FontColor',light);
            headerSubtitle.Layout.Column = 2;
            headerSubtitle.HorizontalAlignment = 'center';

            app.ProViewButton = uibutton(app.HeaderBar,'push', ...
                'Text','Open PRO View', ...
                'BackgroundColor',[0.23 0.35 0.49], ...
                'FontColor',[1 1 1],'FontSize',12);
            app.ProViewButton.Layout.Column = 3;
            app.ProViewButton.ButtonPushedFcn = @(~,~)app.openProfessional();

            app.ControlPanel = uipanel(app.UIFigure,'Title','INTERPOLATION INPUTS', ...
                'Position',[18 107 325 642], 'BackgroundColor',panel, ...
                'ForegroundColor',light,'FontWeight','bold');
            parent = app.ControlPanel;
            app.makeLabel(parent,'Path type',[18 582 285 20]);
            app.ModeDropDown = uidropdown(parent,'Items',{'Linear','Circular'}, ...
                'Value','Linear','Position',[18 550 288 28]);
            app.ModeDropDown.ValueChangedFcn = @(~,~)app.modeChanged();

            app.makeLabel(parent,'Interpolation method',[18 516 285 20]);
            app.MethodDropDown = uidropdown(parent, ...
                'Items',{'Point-by-Point Comparison','DDA'}, ...
                'Value','Point-by-Point Comparison', ...
                'Position',[18 484 288 28]);

            app.makeLabel(parent,'Circular direction',[18 450 285 20]);
            app.DirectionDropDown = uidropdown(parent,'Items',{'CCW','CW'}, ...
                'Value','CCW','Position',[18 418 288 28]);

            app.makeLabel(parent,'Start point (X0, Y0)',[18 383 280 20]);
            app.X0Field = app.makeNumber(parent,0,[18 352 136 28]);
            app.Y0Field = app.makeNumber(parent,0,[170 352 136 28]);

            app.makeLabel(parent,'End point (X1, Y1)',[18 320 280 20]);
            app.X1Field = app.makeNumber(parent,0,[18 289 136 28]);
            app.Y1Field = app.makeNumber(parent,0,[170 289 136 28]);

            app.makeLabel(parent,'Circle center (CX, CY)',[18 257 280 20]);
            app.CXField = app.makeNumber(parent,0,[18 226 136 28]);
            app.CYField = app.makeNumber(parent,0,[170 226 136 28]);

            app.makeLabel(parent,'Animation delay (seconds per point)', ...
                [18 190 285 21]);
            app.DelayField = uieditfield(parent,'numeric', ...
                'Value',0.025,'Limits',[0 1],'Position',[18 159 288 28]);
            uilabel(parent,'Text', ...
                'Coordinates are integer grid steps. For circles, both endpoints must be equally distant from the center.', ...
                'WordWrap','on','FontSize',10, ...
                'FontColor',[0.67 0.76 0.87], ...
                'Position',[18 42 288 54]);
            uilabel(parent,'Text','Try: (12,0) to (0,12), center (0,0)', ...
                'FontSize',10,'FontColor',teal,'Position',[18 14 288 22]);

            app.PlotAxes = uiaxes(app.UIFigure,'Position',[369 331 650 416]);
            app.PlotAxes.Color = [0.085 0.13 0.19];
            app.PlotAxes.XColor = light;
            app.PlotAxes.YColor = light;
            app.PlotAxes.GridColor = [0.45 0.54 0.63];
            app.PlotAxes.FontSize = 11;
            title(app.PlotAxes,'Interpolated toolpath','Color',light);
            xlabel(app.PlotAxes,'X (steps)');
            ylabel(app.PlotAxes,'Y (steps)');
            grid(app.PlotAxes,'on');
            axis(app.PlotAxes,'equal');
            drawCNCXYOrigin(app.PlotAxes,[]); % Show X=0/Y=0 on launch.

            app.ResultsPanel = uipanel(app.UIFigure,'Title','RUN METRICS', ...
                'Position',[1037 331 261 416], 'BackgroundColor',panel, ...
                'ForegroundColor',light,'FontWeight','bold');
            % With navigation now in the global header, RUN METRICS is
            % dedicated to the four metrics and the playback status.
            app.makeLabel(app.ResultsPanel,'Generated pulse cycles',[17 360 226 21]);
            app.PulseLabel = app.makeMetric(app.ResultsPanel,'--',[17 329 226 30],teal);
            app.makeLabel(app.ResultsPanel,'Discrete path length',[17 280 226 21]);
            app.LengthLabel = app.makeMetric(app.ResultsPanel,'--',[17 249 226 30],light);
            app.makeLabel(app.ResultsPanel,'Maximum geometric error',[17 200 230 21]);
            app.ErrorLabel = app.makeMetric(app.ResultsPanel,'--',[17 169 226 30],light);
            app.makeLabel(app.ResultsPanel,'Circular sweep (degrees)',[17 120 226 21]);
            app.SweepLabel = app.makeMetric(app.ResultsPanel,'--',[17 89 226 30],light);
            app.StatusLabel = uilabel(app.ResultsPanel,'Text','Ready. Generate a path.', ...
                'WordWrap','on','FontSize',11,'FontColor',teal, ...
                'Position',[17 8 226 52]);

            app.OutputTable = uitable(app.UIFigure,'Position',[369 107 929 210], ...
                'ColumnEditable',[false false false false]);
            app.OutputTable.Data = table([],[],[],[], ...
                'VariableNames',{'Pulse','X','Y','Deviation'});

            % One control row leaves room for the fixed reference-style
            % legend along the very bottom of the application.
            app.ComputeButton = uibutton(app.UIFigure,'push', ...
                'Text','Generate Path','Position',[18 62 146 38], ...
                'BackgroundColor',teal,'FontWeight','bold');
            app.ComputeButton.ButtonPushedFcn = @(~,~)app.computePath();
            app.StepButton = uibutton(app.UIFigure,'push', ...
                'Text','Step +1','Position',[174 62 110 38]);
            app.StepButton.ButtonPushedFcn = @(~,~)app.stepPath();
            app.AnimateButton = uibutton(app.UIFigure,'push', ...
                'Text','Animate','Position',[294 62 103 38]);
            app.AnimateButton.ButtonPushedFcn = @(~,~)app.animatePath();
            app.PauseButton = uibutton(app.UIFigure,'push', ...
                'Text','Pause','Position',[407 62 85 38]);
            app.PauseButton.ButtonPushedFcn = @(~,~)app.pausePath();
            app.ResetButton = uibutton(app.UIFigure,'push', ...
                'Text','Reset','Position',[502 62 85 38]);
            app.ResetButton.ButtonPushedFcn = @(~,~)app.resetPath();
            app.ExportButton = uibutton(app.UIFigure,'push', ...
                'Text','Export CSV','Position',[1148 62 150 38]);
            app.ExportButton.ButtonPushedFcn = @(~,~)app.exportPath();
            app.RegisterButton = uibutton(app.UIFigure,'push', ...
                'Text','DDA Registers / Import', ...
                'Position',[610 62 208 38], ...
                'BackgroundColor',[0.22 0.35 0.49], ...
                'FontColor',[0.96 0.98 1.00], ...
                'FontWeight','bold');
            app.RegisterButton.ButtonPushedFcn = @(~,~)app.openRegisterLab();
            uilabel(app.UIFigure,'Text', ...
                'Educational simulation - not machine G-code', ...
                'FontColor',[0.58 0.72 0.85],'FontSize',10, ...
                'Position',[833 69 307 24]);

            % Fixed six-key legend, intentionally NOT a MATLAB axes legend:
            % the six symbols remain visible before generation, during
            % playback, and for both linear and circular interpolation.
            % Center C is displayed on the plot for circular mode only.
            app.LegendPanel = uipanel(app.UIFigure, ...
                'Position',[18 10 1280 44], ...
                'BackgroundColor',[0.09 0.135 0.20], ...
                'BorderType','line','BorderColor',[0.43 0.54 0.68]);
            app.makeLegendItem(app.LegendPanel,'- - -','Command path', ...
                22,48,150,[0.97 0.98 1.00]);
            app.makeLegendItem(app.LegendPanel,repmat(char(9473),1,3), ...
                'Interpolated path',235,46,165,[1.00 0.53 0.72]);
            app.makeLegendItem(app.LegendPanel,char(9679),'Start S', ...
                490,26,100,[0.16 0.92 0.85]);
            app.makeLegendItem(app.LegendPanel,char(9632),'End E', ...
                657,26,97,[1.00 0.80 0.38]);
            app.makeLegendItem(app.LegendPanel,char(9679),'Center C', ...
                818,26,120,[0.00 0.81 1.00]);
            app.makeLegendItem(app.LegendPanel,char(9679),'Current point', ...
                1009,26,169,[1.00 0.53 0.72]);

            app.modeChanged();
        end

        function makeLabel(~,parent,textValue,location)
            uilabel(parent,'Text',textValue,'FontSize',12, ...
                'FontColor',[0.83 0.90 0.98],'Position',location);
        end

        function makeLegendItem(~,parent,symbol,caption,x,markWidth,labelWidth,color)
            % Label-based swatches work with AppBase/uifigure (no toolboxes).
            uilabel(parent,'Text',symbol,'Position',[x 8 markWidth 25], ...
                'FontName','Arial','FontSize',19,'FontWeight','bold', ...
                'FontColor',color,'HorizontalAlignment','center');
            uilabel(parent,'Text',caption, ...
                'Position',[x+markWidth+6 9 labelWidth 23], ...
                'FontName','Arial','FontSize',12,'FontWeight','bold', ...
                'FontColor',[0.96 0.98 1.00]);
        end

        function field = makeNumber(~,parent,value,location)
            field = uieditfield(parent,'numeric','Value',value, ...
                'ValueDisplayFormat','%.0f','Position',location);
        end

        function label = makeMetric(~,parent,textValue,location,color)
            label = uilabel(parent,'Text',textValue,'Position',location, ...
                'FontSize',21,'FontWeight','bold','FontColor',color);
        end

        function modeChanged(app)
            circular = strcmp(app.ModeDropDown.Value,'Circular');
            if circular
                app.CXField.Enable = 'on';
                app.CYField.Enable = 'on';
                app.DirectionDropDown.Enable = 'on';
            else
                app.CXField.Enable = 'off';
                app.CYField.Enable = 'off';
                app.DirectionDropDown.Enable = 'off';
            end
        end

        function openProfessional(app)
            % Open once; subsequent clicks bring the same PRO window back.
            if isempty(app.ProfessionalApp) || ~isvalid(app.ProfessionalApp)
                app.ProfessionalApp = CNCProfessionalDashboard(app);
            elseif ~isgraphics(app.ProfessionalApp.UIFigure)
                app.ProfessionalApp = CNCProfessionalDashboard(app);
            else
                app.ProfessionalApp.UIFigure.Visible = 'on';
                app.ProfessionalApp.UIFigure.WindowState = 'normal';
            end
        end

        function openRegisterLab(app)
            % Independent register lab: preserves the main app controls,
            % six-item legend, and geometric algorithms.
            if ~isempty(app.DDALabFigure) && isvalid(app.DDALabFigure)
                app.DDALabFigure.Visible = 'on';
                drawnow;
                return;
            end
            navy = [0.075 0.105 0.16];
            panel = [0.11 0.155 0.225];
            light = [0.91 0.96 1];
            teal = [0.20 0.86 0.76];
            app.DDALabFigure = uifigure('Name','DDA Register Lab | X / Y', ...
                'Position',[170 110 1190 735],'Color',navy);
            app.DDALabFigure.CloseRequestFcn = @(~,~)app.closeRegisterLab();
            uilabel(app.DDALabFigure,'Text','DDA BINARY REGISTER LAB', ...
                'FontName','Arial','FontSize',22,'FontWeight','bold', ...
                'FontColor',light,'Position',[22 684 650 38]);
            uilabel(app.DDALabFigure, ...
                'Text','X-axis: J_vx + J_rx    |    Y-axis: J_vy + J_ry    |    overflow = pulse', ...
                'FontColor',[0.64 0.78 0.91], ...
                'Position',[22 665 850 22]);

            registerPanel = uipanel(app.DDALabFigure, ...
                'Title','INITIAL BINARY REGISTERS', ...
                'Position',[20 515 1150 145], ...
                'BackgroundColor',panel,'ForegroundColor',light, ...
                'FontWeight','bold');
            labels = {'J_vx  (X velocity)','J_rx  (X remainder)', ...
                      'J_vy  (Y velocity)','J_ry  (Y remainder)', ...
                      'N (bits)','Cycles'};
            positions = [20 210 400 590 790 955];
            for k = 1:numel(labels)
                app.makeLabel(registerPanel,labels{k}, ...
                    [positions(k) 94 184 22]);
            end
            app.RegisterVXField = uieditfield(registerPanel,'text', ...
                'Value','101','FontName','Consolas','FontSize',15, ...
                'Position',[20 58 172 32]);
            app.RegisterRXField = uieditfield(registerPanel,'text', ...
                'Value','000','FontName','Consolas','FontSize',15, ...
                'Position',[210 58 172 32]);
            app.RegisterVYField = uieditfield(registerPanel,'text', ...
                'Value','011','FontName','Consolas','FontSize',15, ...
                'Position',[400 58 172 32]);
            app.RegisterRYField = uieditfield(registerPanel,'text', ...
                'Value','000','FontName','Consolas','FontSize',15, ...
                'Position',[590 58 172 32]);
            app.RegisterBitsField = uieditfield(registerPanel,'numeric', ...
                'Value',3,'Limits',[1 16], ...
                'ValueDisplayFormat','%.0f','Position',[790 58 143 32]);
            app.RegisterCyclesField = uieditfield(registerPanel,'numeric', ...
                'Value',8,'Limits',[1 20000], ...
                'ValueDisplayFormat','%.0f','Position',[955 58 166 32]);
            uilabel(registerPanel,'Text', ...
                'Binary 0/1 digits; the accumulator retains N low bits. The carry/overflow emits X and/or Y pulses.', ...
                'FontColor',[0.64 0.78 0.91], ...
                'Position',[20 16 1100 24]);

            app.RegisterImportButton = uibutton(app.DDALabFigure,'push', ...
                'Text','Import CSV / XLSX / TXT / MAT', ...
                'Position',[20 464 271 39], ...
                'BackgroundColor',[0.22 0.35 0.49], ...
                'FontColor',light,'FontWeight','bold');
            app.RegisterImportButton.ButtonPushedFcn = ...
                @(~,~)app.importRegisterFile();
            app.RegisterComputeButton = uibutton(app.DDALabFigure,'push', ...
                'Text','Calculate Registers', ...
                'Position',[303 464 190 39], ...
                'BackgroundColor',teal,'FontWeight','bold');
            app.RegisterComputeButton.ButtonPushedFcn = ...
                @(~,~)app.computeRegisters();
            app.RegisterStepButton = uibutton(app.DDALabFigure,'push', ...
                'Text','Step +1', 'Position',[505 464 137 39]);
            app.RegisterStepButton.ButtonPushedFcn = ...
                @(~,~)app.stepRegisters();
            app.RegisterExportButton = uibutton(app.DDALabFigure,'push', ...
                'Text','Export Trace CSV','Position',[654 464 170 39]);
            app.RegisterExportButton.ButtonPushedFcn = ...
                @(~,~)app.exportRegisterTrace();
            uilabel(app.DDALabFigure,'Text', ...
                'Classroom example: J_vx = 101, J_vy = 011, N = 3', ...
                'FontColor',teal,'Position',[846 469 330 28]);

            app.RegisterTable = uitable(app.DDALabFigure, ...
                'Position',[20 90 804 359], ...
                'ColumnEditable',false(1,9));
            app.RegisterTable.ColumnWidth = {55 72 72 78 72 72 78 65 65};
            app.RegisterAxes = uiaxes(app.DDALabFigure, ...
                'Position',[842 102 326 342]);
            app.RegisterAxes.Color = [0.085 0.13 0.19];
            app.RegisterAxes.XColor = light;
            app.RegisterAxes.YColor = light;
            app.RegisterAxes.GridColor = [0.45 0.54 0.63];
            title(app.RegisterAxes,'DDA pulse path','Color',light);
            xlabel(app.RegisterAxes,'X pulses');
            ylabel(app.RegisterAxes,'Y pulses');
            grid(app.RegisterAxes,'on');
            axis(app.RegisterAxes,'equal');
            drawCNCXYOrigin(app.RegisterAxes,[]);
            app.RegisterStatusLabel = uilabel(app.DDALabFigure, ...
                'Text','Ready to import or calculate register clocks.', ...
                'FontSize',12,'FontColor',teal, ...
                'Position',[22 48 1120 27]);
            uilabel(app.DDALabFigure,'Text', ...
                ['J_vx/J_vy are fixed velocity increments; J_rx/J_ry are ', ...
                 'updated accumulator registers. Step 0 = initial state.'], ...
                'FontColor',[0.59 0.72 0.85], ...
                'Position',[22 15 1120 25]);
            app.RegisterResult = [];
            app.RegisterCursor = 1;
            app.computeRegisters();
        end

        function computeRegisters(app)
            if isempty(app.DDALabFigure) || ~isvalid(app.DDALabFigure)
                return;
            end
            try
                result = ddaRegisterTrace( ...
                    app.RegisterVXField.Value,app.RegisterRXField.Value, ...
                    app.RegisterVYField.Value,app.RegisterRYField.Value, ...
                    app.RegisterBitsField.Value,app.RegisterCyclesField.Value);
                app.RegisterResult = result;
                app.RegisterCursor = 1;
                app.RegisterTable.Data = result.Table;
                p = result.Points;
                ax = app.RegisterAxes;
                cla(ax);
                hold(ax,'on');
                drawCNCXYOrigin(ax,p);
                plot(ax,p(:,1),p(:,2),'--','Color',[0.87 0.91 0.96], ...
                    'LineWidth',1.1);
                app.RegisterLiveLine = plot(ax,p(1,1),p(1,2),'-', ...
                    'Color',[1.00 0.53 0.72],'LineWidth',2.5);
                plot(ax,p(1,1),p(1,2),'o','LineStyle','none', ...
                    'MarkerFaceColor',[0.16 0.92 0.85],'MarkerSize',8);
                plot(ax,p(end,1),p(end,2),'s','LineStyle','none', ...
                    'MarkerFaceColor',[1.00 0.80 0.38],'MarkerSize',8);
                app.RegisterCurrentPoint = plot(ax,p(1,1),p(1,2),'o', ...
                    'MarkerFaceColor',[1.00 0.53 0.72], ...
                    'MarkerEdgeColor',[1 1 1],'MarkerSize',9);
                grid(ax,'on');
                axis(ax,'equal');
                hold(ax,'off');
                app.RegisterStatusLabel.Text = sprintf( ...
                    'Generated %d clocks (N=%d bits). X pulses: %d  |  Y pulses: %d. Click Step +1 to replay.', ...
                    result.Cycles,result.NBits,result.PulseX,result.PulseY);
            catch err
                app.RegisterResult = [];
                app.RegisterStatusLabel.Text = 'Invalid DDA register data.';
                uialert(app.DDALabFigure,err.message,'DDA register error');
            end
        end

        function stepRegisters(app)
            if isempty(app.RegisterResult)
                app.computeRegisters();
                if isempty(app.RegisterResult),return;end
            end
            app.RegisterCursor = min(app.RegisterCursor+1, ...
                size(app.RegisterResult.Points,1));
            p = app.RegisterResult.Points(1:app.RegisterCursor,:);
            app.RegisterLiveLine.XData = p(:,1);
            app.RegisterLiveLine.YData = p(:,2);
            app.RegisterCurrentPoint.XData = p(end,1);
            app.RegisterCurrentPoint.YData = p(end,2);
            tab = app.RegisterResult.Table;
            idx = app.RegisterCursor;
            app.RegisterStatusLabel.Text = sprintf( ...
                'Clock %d / %d  |  J_rx=%s (X carry %d)  |  J_ry=%s (Y carry %d)  |  X=%d Y=%d', ...
                idx-1,app.RegisterResult.Cycles, ...
                tab.J_rx{idx},tab.PulseX(idx), ...
                tab.J_ry{idx},tab.PulseY(idx),tab.X(idx),tab.Y(idx));
        end

        function importRegisterFile(app)
            [name,folder] = uigetfile( ...
                {'*.csv;*.tsv;*.txt;*.xlsx;*.mat', ...
                 'DDA register files (*.csv, *.tsv, *.txt, *.xlsx, *.mat)'}, ...
                'Import DDA X/Y registers');
            if isequal(name,0),return;end
            try
                config = readDDARegisters(fullfile(folder,name));
                app.RegisterVXField.Value = config.J_vx;
                app.RegisterRXField.Value = config.J_rx;
                app.RegisterVYField.Value = config.J_vy;
                app.RegisterRYField.Value = config.J_ry;
                app.RegisterBitsField.Value = config.NBits;
                app.RegisterCyclesField.Value = config.Cycles;
                app.computeRegisters();
                if ~isempty(app.RegisterResult)
                    app.RegisterStatusLabel.Text = sprintf( ...
                        'Imported %s - X: J_vx=%s J_rx=%s  |  Y: J_vy=%s J_ry=%s', ...
                        name,config.J_vx,config.J_rx,config.J_vy,config.J_ry);
                end
            catch err
                uialert(app.DDALabFigure,err.message,'Register file import failed');
            end
        end

        function exportRegisterTrace(app)
            if isempty(app.RegisterResult)
                uialert(app.DDALabFigure, ...
                    'Calculate the registers before exporting.','No register trace');
                return;
            end
            [name,folder] = uiputfile('*.csv', ...
                'Export DDA register trace','dda_register_trace.csv');
            if isequal(name,0),return;end
            try
                writetable(app.RegisterResult.Table,fullfile(folder,name));
                app.RegisterStatusLabel.Text = 'DDA register trace CSV exported.';
            catch err
                uialert(app.DDALabFigure,err.message,'Register export failed');
            end
        end

        function closeRegisterLab(app)
            if ~isempty(app.DDALabFigure) && isvalid(app.DDALabFigure)
                delete(app.DDALabFigure);
            end
            app.DDALabFigure = [];
            app.RegisterResult = [];
        end

        function computePath(app)
            app.IsPlaying = false;
            try
                app.Result = interpolatePath(app.ModeDropDown.Value, ...
                    app.MethodDropDown.Value, ...
                    [app.X0Field.Value,app.Y0Field.Value], ...
                    [app.X1Field.Value,app.Y1Field.Value], ...
                    [app.CXField.Value,app.CYField.Value], ...
                    app.DirectionDropDown.Value);
                app.Cursor = 1;
                r = app.Result;
                app.PulseLabel.Text = sprintf('%d',r.info.PulseCycles);
                app.LengthLabel.Text = sprintf('%.3f steps',r.info.PathLength);
                app.ErrorLabel.Text = sprintf('%.4f steps',r.info.MaxDeviation);
                if isnan(r.info.SweepDegrees)
                    app.SweepLabel.Text = 'N/A (line)';
                else
                    app.SweepLabel.Text = sprintf('%.1f deg',r.info.SweepDegrees);
                end
                pts = r.points;
                app.OutputTable.Data = table((0:size(pts,1)-1)',pts(:,1), ...
                    pts(:,2),r.deviation, ...
                    'VariableNames',{'Pulse','X','Y','Deviation'});
                app.drawPath();
                app.StatusLabel.Text = 'Path generated. Step or Animate to play.';
            catch err
                app.Result = [];
                app.StatusLabel.Text = 'Invalid geometry or inputs.';
                uialert(app.UIFigure,err.message,'Interpolation error');
            end
        end

        function drawPath(app)
            r = app.Result;
            p = r.points;
            ax = app.PlotAxes;
            cla(ax);
            legend(ax,'off'); % The persistent six-item legend is below the UI.
            hold(ax,'on');
            % Cartesian origin and zero axes remain fixed in the middle.
            viewPoints = [p;r.ideal];
            if strcmp(r.info.PathType,'Circular')
                viewPoints = [viewPoints;app.CXField.Value,app.CYField.Value];
            end
            drawCNCXYOrigin(ax,viewPoints);

            % Command path: ideal geometry, represented by a white dash.
            plot(ax,r.ideal(:,1),r.ideal(:,2),'--', ...
                'Color',[0.97 0.98 1.00],'LineWidth',1.7);

            % Interpolated path: the pink trace grows as pulses are played.
            app.LiveLine = plot(ax,p(1,1),p(1,2),'-', ...
                'Color',[1.00 0.53 0.72],'LineWidth',2.4);

            % Reference-style markers: S = teal circle; E = yellow square.
            plot(ax,p(1,1),p(1,2),'o','LineStyle','none', ...
                'MarkerSize',9,'MarkerFaceColor',[0.16 0.92 0.85], ...
                'MarkerEdgeColor',[0.07 0.14 0.19]);
            plot(ax,p(end,1),p(end,2),'s','LineStyle','none', ...
                'MarkerSize',9,'MarkerFaceColor',[1.00 0.80 0.38], ...
                'MarkerEdgeColor',[0.07 0.14 0.19]);

            % C = blue circle, only meaningful for circular interpolation.
            if strcmp(r.info.PathType,'Circular')
                centerXY = [app.CXField.Value,app.CYField.Value];
                plot(ax,centerXY(1),centerXY(2),'o','LineStyle','none', ...
                    'MarkerSize',8,'MarkerFaceColor',[0.00 0.81 1.00], ...
                    'MarkerEdgeColor',[0.07 0.14 0.19]);
            end

            % Current point: independent pink dot, updated on every step.
            app.CurrentMarker = plot(ax,p(1,1),p(1,2),'o', ...
                'LineStyle','none','MarkerSize',10, ...
                'MarkerFaceColor',[1.00 0.53 0.72], ...
                'MarkerEdgeColor',[1.00 0.98 1.00]);
            title(ax,[r.info.PathType,' / ',r.info.Method], ...
                'Color',[0.92 0.96 1.0]);
            xlabel(ax,'X (grid steps)');
            ylabel(ax,'Y (grid steps)');
            grid(ax,'on');
            axis(ax,'equal');
            hold(ax,'off');
        end

        function updatePlayback(app)
            if isempty(app.Result) || isempty(app.LiveLine) || ...
                    ~isgraphics(app.LiveLine) || ...
                    isempty(app.CurrentMarker) || ...
                    ~isgraphics(app.CurrentMarker)
                return;
            end
            segment = app.Result.points(1:app.Cursor,:);
            app.LiveLine.XData = segment(:,1);
            app.LiveLine.YData = segment(:,2);
            % The current point must follow the final interpolated sample.
            app.CurrentMarker.XData = segment(end,1);
            app.CurrentMarker.YData = segment(end,2);
            app.StatusLabel.Text = sprintf('Playback: %d / %d cycles', ...
                app.Cursor-1,app.Result.info.PulseCycles);
        end

        function stepPath(app)
            if isempty(app.Result)
                app.computePath();
                if isempty(app.Result),return;end
            end
            app.IsPlaying = false;
            app.Cursor = min(app.Cursor+1,size(app.Result.points,1));
            app.updatePlayback();
        end

        function animatePath(app)
            if isempty(app.Result)
                app.computePath();
                if isempty(app.Result),return;end
            end
            if app.IsPlaying,return;end
            app.IsPlaying = true;
            while app.IsPlaying && app.Cursor<size(app.Result.points,1) ...
                    && isvalid(app.UIFigure)
                app.Cursor = app.Cursor+1;
                app.updatePlayback();
                drawnow;
                pause(app.DelayField.Value);
            end
            app.IsPlaying = false;
            if isvalid(app.UIFigure) && app.Cursor>=size(app.Result.points,1)
                app.StatusLabel.Text = 'Playback complete.';
            end
        end

        function pausePath(app)
            app.IsPlaying = false;
        end

        function resetPath(app)
            app.IsPlaying = false;
            if ~isempty(app.Result)
                app.Cursor = 1;
                app.updatePlayback();
            end
        end

        function exportPath(app)
            if isempty(app.Result)
                uialert(app.UIFigure,'Generate a path before exporting.','No data');
                return;
            end
            [name,folder] = uiputfile('*.csv','Export interpolation points', ...
                'interpolation_points.csv');
            if isequal(name,0),return;end
            try
                writetable(app.OutputTable.Data,fullfile(folder,name));
                app.StatusLabel.Text = 'CSV exported successfully.';
            catch err
                uialert(app.UIFigure,err.message,'Export failed');
            end
        end
    end

    methods (Access = public)
        function app = CNCInterpolationApp(existingProfessional)
            app.createComponents();
            if nargin >= 1 && ~isempty(existingProfessional) && ...
                    isa(existingProfessional,'CNCProfessionalDashboard') && ...
                    isvalid(existingProfessional)
                app.ProfessionalApp = existingProfessional;
            end
            registerApp(app,app.UIFigure);
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            app.IsPlaying = false;
            app.closeRegisterLab();
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
