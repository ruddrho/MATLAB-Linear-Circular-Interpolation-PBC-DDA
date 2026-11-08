classdef CNCProfessionalDashboard < matlab.apps.AppBase
%CNCPROFESSIONALDASHBOARD Professional MATLAB App Designer-style workspace.
% All UI is built with MATLAB UIFigure/uigridlayout (no add-on toolboxes).
% Separate from the original CNCInterpolationApp, which remains available.

    properties (Access = public)
        UIFigure
        Tabs
        PathType
        Method
        Direction
        X0
        Y0
        X1
        Y1
        CX
        CY
        Delay
        SimAxes
        SimTable
        StatusLabel
        StepLabel
        SpeedSlider
        ErrorCurveAxes
        ErrorBarsAxes
        ErrorInfoLabel
        MaxErrorLabel
        EndErrorLabel
        PathLengthLabel
        SweepLabel
        PBCPlot
        DDAPlot
        CompareTable
        CompareStatus
        VX
        RX
        VY
        RY
        Bits
        Cycles
        RegisterAxes
        RegisterTable
        RegisterStatus
        CodeEditor
        GCodeAxes
        GCodeTable
        GCodeStatus
        ExportStatus
        ThemeChoice
    end

    properties (Access = private)
        Result = []
        Comparison = []
        Registers = []
        GCodeProgram = []
        PathCursor = 1
        RegisterCursor = 1
        Running = false
        SimLine = []
        SimMarker = []
        RegLine = []
        RegMarker = []
        ClassicApp = []
        ThemePanels = {}
        ThemeAxes = {}
        ThemeLabels = {}
        Dark = true
    end

    methods (Access = private)
        function createComponents(app)
            bg=[.065 .090 .145]; panel=[.105 .15 .225]; text=[.92 .96 1];
            app.UIFigure=uifigure('Name','CNC Interpolation Studio PRO', ...
                'Position',[65 55 1490 910], 'Color',bg);
            app.UIFigure.CloseRequestFcn=@(~,~)delete(app);
            root=uigridlayout(app.UIFigure,[2 1]);
            root.RowHeight={68,'1x'}; root.ColumnWidth={'1x'};
            root.Padding=[15 12 15 12];root.RowSpacing=9;
            root.BackgroundColor=bg;
            heading=uigridlayout(root,[1 3]);
            heading.Layout.Row=1;
            heading.ColumnWidth={'2x','3x',190};
            heading.BackgroundColor=bg;heading.Padding=[6 0 6 0];
            a=app.label(heading,'CNC INTERPOLATION STUDIO PRO',22,true);
            a.Layout.Column=1;
            a=app.label(heading,'PBC / DDA  •  2D Toolpaths  •  Register Lab  •  G-code  •  Reports',12,false);
            a.Layout.Column=2;
            classic=uibutton(heading,'push','Text','Open Classic View', ...
                'BackgroundColor',[.23 .35 .49],'FontColor',[1 1 1]);
            classic.Layout.Column=3;
            classic.ButtonPushedFcn=@(~,~)app.openClassic();

            app.Tabs=uitabgroup(root);
            app.Tabs.Layout.Row=2;
            sim=uitab(app.Tabs,'Title','01  SIMULATION');
            comp=uitab(app.Tabs,'Title','02  PBC vs DDA');
            errors=uitab(app.Tabs,'Title','03  ERROR ANALYSIS');
            reg=uitab(app.Tabs,'Title','04  BINARY REGISTER LAB');
            gcode=uitab(app.Tabs,'Title','05  G-CODE PREVIEW');
            exports=uitab(app.Tabs,'Title','06  REPORTS & PROJECT');
            app.makeSimulationTab(sim);
            app.makeComparisonTab(comp);
            app.makeErrorTab(errors);
            app.makeRegisterTab(reg);
            app.makeGcodeTab(gcode);
            app.makeExportTab(exports);
            % All XY toolpath views start with visible centered X=0/Y=0.
            xyViews={app.SimAxes,app.PBCPlot,app.DDAPlot, ...
                app.RegisterAxes,app.GCodeAxes};
            for k=1:numel(xyViews)
                drawCNCXYOrigin(xyViews{k},[]);
            end
            app.applyTheme('Dark');
            % The startup mode is Linear + Point-by-Point Comparison.
            % Disable circle-only controls until Circular is selected.
            app.modeChanged();
            % Fresh sessions start with all geometry fields at zero.
            % Do not generate a path until the user presses Generate Path.
            app.StatusLabel.Text = ...
                'Ready: Linear / Point-by-Point Comparison. All coordinates are 0.';
        end

        function h=panel(app,parent,titleText)
            h=uipanel(parent,'Title',titleText,'FontWeight','bold', ...
                'BackgroundColor',[.105 .15 .225], ...
                'ForegroundColor',[.92 .96 1]);
            app.ThemePanels{end+1}=h;
        end
        function h=label(app,parent,stringValue,sz,bold)
            if nargin<5,bold=false;end
            h=uilabel(parent,'Text',stringValue,'FontSize',sz, ...
                'FontColor',[.87 .94 1]);
            if bold,h.FontWeight='bold';end
            app.ThemeLabels{end+1}=h;
        end
        function h=number(~,parent,value)
            h=uieditfield(parent,'numeric','Value',value, ...
                'ValueDisplayFormat','%.0f');
        end
        function setRow(~,ctrl,row,col)
            ctrl.Layout.Row=row;
            ctrl.Layout.Column=col;
        end
        function h=button(~,parent,txt,fun,accent)
            if nargin<5,accent=false;end
            h=uibutton(parent,'push','Text',txt);
            h.ButtonPushedFcn=@(~,~)fun();
            if accent
                h.BackgroundColor=[.13 .75 .79];
                h.FontColor=[.02 .09 .14];
                h.FontWeight='bold';
            end
        end
        function h=axes(app,parent,titleText)
            h=uiaxes(parent);
            h.Color=[.085 .13 .19];
            h.XColor=[.91 .96 1];h.YColor=[.91 .96 1];
            h.GridColor=[.45 .54 .63];h.FontSize=11;
            title(h,titleText,'Color',[.92 .96 1]);
            xlabel(h,'X (grid steps)');ylabel(h,'Y (grid steps)');
            grid(h,'on');axis(h,'equal');
            app.ThemeAxes{end+1}=h;
        end
        function makeSimulationTab(app,tab)
            g=uigridlayout(tab,[3 3]);
            g.RowHeight={'1x',210,43};
            g.ColumnWidth={335,'2.3x','0.95x'};
            g.Padding=[12 12 12 12];g.RowSpacing=11;g.ColumnSpacing=12;
            form=app.panel(g,'PATH & ANIMATION SETTINGS');
            form.Layout.Row=[1 2];form.Layout.Column=1;
            f=uigridlayout(form,[17 2]);
            f.RowHeight={26,22,30,28,22,30,23,30,23,30,23,30,35,34,34,34,'1x'};
            f.ColumnWidth={'1x','1x'};
            f.Padding=[11 10 11 9];f.RowSpacing=4;f.ColumnSpacing=8;
            q=app.label(f,'Path type',11,true);app.setRow(q,1,1);
            q=app.label(f,'Algorithm',11,true);app.setRow(q,1,2);
            app.PathType=uidropdown(f,'Items',{'Linear','Circular'},'Value','Linear');
            app.setRow(app.PathType,2,1);app.PathType.Layout.Row=3;
            app.PathType.ValueChangedFcn=@(~,~)app.modeChanged();
            app.Method=uidropdown(f,'Items',{'Point-by-Point Comparison','DDA'},'Value','Point-by-Point Comparison');
            app.setRow(app.Method,3,2);
            q=app.label(f,'Circular direction',11,true);app.setRow(q,4,1);
            q=app.label(f,'Delay (s / step)',11,true);app.setRow(q,4,2);
            app.Direction=uidropdown(f,'Items',{'CCW','CW'},'Value','CCW');
            app.setRow(app.Direction,6,1);
            app.Delay=uieditfield(f,'numeric','Value',.025,'Limits',[0 1]);
            app.setRow(app.Delay,6,2);
            app.Delay.ValueChangedFcn=@(~,~)app.syncSpeed();
            q=app.label(f,'Start X',11,true);app.setRow(q,7,1);
            q=app.label(f,'Start Y',11,true);app.setRow(q,7,2);
            app.X0=app.number(f,0);app.setRow(app.X0,8,1);
            app.Y0=app.number(f,0);app.setRow(app.Y0,8,2);
            q=app.label(f,'End X',11,true);app.setRow(q,9,1);
            q=app.label(f,'End Y',11,true);app.setRow(q,9,2);
            app.X1=app.number(f,0);app.setRow(app.X1,10,1);
            app.Y1=app.number(f,0);app.setRow(app.Y1,10,2);
            q=app.label(f,'Center X',11,true);app.setRow(q,11,1);
            q=app.label(f,'Center Y',11,true);app.setRow(q,11,2);
            app.CX=app.number(f,0);app.setRow(app.CX,12,1);
            app.CY=app.number(f,0);app.setRow(app.CY,12,2);
            b=app.button(f,'Generate Path',@()app.generatePath(),true);app.setRow(b,13,[1 2]);
            b=app.button(f,'Animate',@()app.animatePath(),true);app.setRow(b,14,1);
            b=app.button(f,'Pause',@()app.pausePath());app.setRow(b,14,2);
            b=app.button(f,'Step -1',@()app.moveStep(-1));app.setRow(b,15,1);
            b=app.button(f,'Step +1',@()app.moveStep(1));app.setRow(b,15,2);
            b=app.button(f,'Reset Playback',@()app.resetPath());app.setRow(b,16,[1 2]);
            % Large screen layout: form is scrollable on shorter displays.
            f.Scrollable='on';

            app.SimAxes=app.axes(g,'Interpolated trajectory');
            app.SimAxes.Layout.Row=1;app.SimAxes.Layout.Column=2;
            metrics=app.panel(g,'REAL-TIME METRICS');
            metrics.Layout.Row=1;metrics.Layout.Column=3;
            mg=uigridlayout(metrics,[13 1]);
            mg.RowHeight={25,28,16,25,28,16,25,28,16,25,28,'1x',38};
            mg.Padding=[13 12 13 8];
            q=app.label(mg,'CLOCK / PULSE CYCLES',10,true);app.setRow(q,1,1);
            app.StepLabel=app.label(mg,'0 / 0',20,true);app.setRow(app.StepLabel,2,1);
            q=app.label(mg,'MAXIMUM DEVIATION',10,true);app.setRow(q,4,1);
            app.MaxErrorLabel=app.label(mg,'--',19,true);app.setRow(app.MaxErrorLabel,5,1);
            q=app.label(mg,'ENDPOINT ERROR',10,true);app.setRow(q,7,1);
            app.EndErrorLabel=app.label(mg,'--',19,true);app.setRow(app.EndErrorLabel,8,1);
            q=app.label(mg,'DISCRETE PATH LENGTH',10,true);app.setRow(q,10,1);
            app.PathLengthLabel=app.label(mg,'--',19,true);app.setRow(app.PathLengthLabel,11,1);
            % Native uislider tick labels inherit low-contrast system
            % colors in some MATLAB releases (black on dark blue). Hide
            % those labels and render explicit themed uilabels instead.
            % Keep the slider editable and synchronized with Delay.
            sliderArea=uigridlayout(mg,[4 1]);
            sliderArea.Layout.Row=12;
            sliderArea.RowHeight={22,30,22,'1x'};
            sliderArea.ColumnWidth={'1x'};
            sliderArea.RowSpacing=0;
            sliderArea.Padding=[2 5 2 0];
            q=app.label(sliderArea,'ANIMATION DELAY (SECONDS / STEP)',10,true);
            q.Layout.Row=1;
            app.SpeedSlider=uislider(sliderArea,'Limits',[0 1], ...
                'Value',.025,'MajorTicks',[0 .25 .5 .75 1], ...
                'MajorTickLabels',{'','','','',''},'MinorTicks',[]);
            app.SpeedSlider.Layout.Row=2;
            app.SpeedSlider.ValueChangedFcn=@(~,~)app.useSliderDelay();
            tickRow=uigridlayout(sliderArea,[1 5]);
            tickRow.Layout.Row=3;
            tickRow.RowHeight={22};
            tickRow.ColumnWidth={'1x','1x','1x','1x','1x'};
            tickRow.ColumnSpacing=0;
            tickRow.Padding=[12 0 12 0];
            tickText={'0','0.25','0.50','0.75','1.00'};
            for k=1:5
                q=app.label(tickRow,tickText{k},11,true);
                q.Layout.Column=k;
                if k==1
                    q.HorizontalAlignment='left';
                elseif k==5
                    q.HorizontalAlignment='right';
                else
                    q.HorizontalAlignment='center';
                end
            end
            app.StatusLabel=app.label(mg,'Ready.',10,false);
            app.StatusLabel.WordWrap='on';app.setRow(app.StatusLabel,13,1);
            tablePanel=app.panel(g,'STEP-BY-STEP DECISION LOG');
            tablePanel.Layout.Row=2;tablePanel.Layout.Column=[2 3];
            tg=uigridlayout(tablePanel,[1 1]);tg.Padding=[8 5 8 8];
            app.SimTable=uitable(tg,'ColumnEditable',false(1,7));
            app.SimTable.ColumnWidth={55 70 70 65 65 90 105};
            legendPanel=app.panel(g,'GRAPH LEGEND');
            legendPanel.Layout.Row=3;legendPanel.Layout.Column=[1 3];
            legendGrid=uigridlayout(legendPanel,[1 6]);
            legendGrid.ColumnWidth={'1x','1x','1x','1x','1x','1x'};
            legendGrid.Padding=[10 0 10 0];
            swatches={'- -  Command path','---  Interpolated path', ...
                     '●  Start S','■  End E','●  Center C','●  Current point'};
            colors={[.96 .97 1],[1 .53 .72],[.16 .92 .85], ...
                    [1 .80 .38],[0 .81 1],[1 .53 .72]};
            for j=1:6
                x=app.label(legendGrid,swatches{j},11,true);
                x.FontColor=colors{j};x.Layout.Column=j;
            end
            app.modeChanged();
        end

        function makeComparisonTab(app,tab)
            g=uigridlayout(tab,[3 2]);g.ColumnWidth={'1x','1x'};
            g.RowHeight={52,'1x',235};
            g.Padding=[12 12 12 12];g.RowSpacing=10;g.ColumnSpacing=11;
            toolbar=uigridlayout(g,[1 3]);toolbar.Layout.Row=1;
            toolbar.Layout.Column=[1 2];toolbar.ColumnWidth={225,'1x',255};
            b=app.button(toolbar,'Run PBC vs DDA',@()app.runComparison(),true);
            b.Layout.Column=1;
            q=app.label(toolbar, ...
                'Same geometry • independent pulse counts • geometric error and CPU timing',11,false);
            q.Layout.Column=2;
            b=app.button(toolbar,'Export Comparison CSV',@()app.exportComparison());
            b.Layout.Column=3;
            app.PBCPlot=app.axes(g,'Point-by-Point Comparison');
            app.PBCPlot.Layout.Row=2;app.PBCPlot.Layout.Column=1;
            app.DDAPlot=app.axes(g,'Digital Differential Analyzer');
            app.DDAPlot.Layout.Row=2;app.DDAPlot.Layout.Column=2;
            res=app.panel(g,'COMPARISON RESULTS');res.Layout.Row=3;
            res.Layout.Column=[1 2];
            rr=uigridlayout(res,[2 1]);rr.RowHeight={'1x',38};rr.Padding=[8 5 8 5];
            app.CompareTable=uitable(rr,'ColumnEditable',false(1,7));
            app.CompareTable.ColumnWidth={210 115 120 120 115 120 100};
            app.CompareStatus=app.label(rr, ...
                'Run the two algorithms using coordinates from Simulation.',11,false);
            app.CompareStatus.Layout.Row=2;
        end

        function makeErrorTab(app,tab)
            g=uigridlayout(tab,[3 2]);
            g.ColumnWidth={'1.25x','1x'};
            g.RowHeight={46,'1x',150};
            g.Padding=[12 12 12 12];g.RowSpacing=10;g.ColumnSpacing=11;
            controls=uigridlayout(g,[1 2]);controls.Layout.Row=1;
            controls.Layout.Column=[1 2];controls.ColumnWidth={220,'1x'};
            b=app.button(controls,'Compute Error Curves',@()app.runComparison(),true);
            b.Layout.Column=1;
            q=app.label(controls, ...
                'Per-step geometric deviation for each method; peaks are not servo-following errors.',11,false);
            q.Layout.Column=2;
            app.ErrorCurveAxes=app.axes(g,'Geometric error vs interpolation step');
            app.ErrorCurveAxes.Layout.Row=2;app.ErrorCurveAxes.Layout.Column=1;
            xlabel(app.ErrorCurveAxes,'Step index');
            ylabel(app.ErrorCurveAxes,'Deviation (grid units)');
            app.ErrorBarsAxes=app.axes(g,'Error metric comparison');
            app.ErrorBarsAxes.Layout.Row=2;app.ErrorBarsAxes.Layout.Column=2;
            ylabel(app.ErrorBarsAxes,'Deviation (grid units)');
            insight=app.panel(g,'INTERPRETATION');insight.Layout.Row=3;
            insight.Layout.Column=[1 2];
            ig=uigridlayout(insight,[1 1]);ig.Padding=[12 12 12 10];
            app.ErrorInfoLabel=app.label(ig, ...
                'Run a comparison to display error-by-step traces and geometric error summary.',12,false);
            app.ErrorInfoLabel.WordWrap='on';
        end

        function makeRegisterTab(app,tab)
            g=uigridlayout(tab,[3 2]);
            g.RowHeight={160,46,'1x'};g.ColumnWidth={'1.5x','1x'};
            g.Padding=[12 12 12 12];g.RowSpacing=9;g.ColumnSpacing=11;
            inputs=app.panel(g,'BINARY ACCUMULATOR INITIAL STATE');
            inputs.Layout.Row=1;inputs.Layout.Column=[1 2];
            m=uigridlayout(inputs,[2 6]);
            m.RowHeight={27,36};m.ColumnWidth={'1x','1x','1x','1x','1x','1x'};
            tags={'J_vx','J_rx','J_vy','J_ry','N (bits)','Clock cycles'};
            for j=1:6
                q=app.label(m,tags{j},12,true);app.setRow(q,1,j);
            end
            app.VX=uieditfield(m,'text','Value','101');app.setRow(app.VX,2,1);
            app.RX=uieditfield(m,'text','Value','000');app.setRow(app.RX,2,2);
            app.VY=uieditfield(m,'text','Value','011');app.setRow(app.VY,2,3);
            app.RY=uieditfield(m,'text','Value','000');app.setRow(app.RY,2,4);
            app.Bits=app.number(m,3);app.setRow(app.Bits,2,5);
            app.Cycles=app.number(m,8);app.setRow(app.Cycles,2,6);
            controls=uigridlayout(g,[1 6]);controls.Layout.Row=2;
            controls.Layout.Column=[1 2];
            controls.ColumnWidth={190,130,130,210,175,'1x'};
            labels={'Calculate Registers','Step -1','Step +1', ...
                    'Import CSV / XLSX / MAT','Export Trace CSV'};
            callbacks={@()app.calculateRegisters(),@()app.moveRegister(-1), ...
                @()app.moveRegister(1),@()app.importRegisters(),@()app.exportRegisters()};
            for j=1:5
                b=app.button(controls,labels{j},callbacks{j},j==1);
                b.Layout.Column=j;
            end
            app.RegisterStatus=app.label(controls,'Clock 0',11,true);
            app.RegisterStatus.Layout.Column=6;
            p=app.panel(g,'CLOCK-BY-CLOCK REGISTER TRACE');
            p.Layout.Row=3;p.Layout.Column=1;
            sub=uigridlayout(p,[1 1]);sub.Padding=[8 6 8 7];
            app.RegisterTable=uitable(sub,'ColumnEditable',false(1,9));
            app.RegisterTable.ColumnWidth={65 70 70 76 70 70 76 60 60};
            app.RegisterAxes=app.axes(g,'Accumulated output pulses');
            app.RegisterAxes.Layout.Row=3;app.RegisterAxes.Layout.Column=2;
            app.calculateRegisters();
        end

        function makeGcodeTab(app,tab)
            g=uigridlayout(tab,[3 2]);
            g.RowHeight={48,'1x',250};g.ColumnWidth={460,'1x'};
            g.Padding=[12 12 12 12];g.ColumnSpacing=11;g.RowSpacing=10;
            tools=uigridlayout(g,[1 4]);tools.Layout.Row=1;
            tools.Layout.Column=[1 2];tools.ColumnWidth={160,160,180,'1x'};
            b=app.button(tools,'Preview G-code',@()app.previewGcode(),true);b.Layout.Column=1;
            b=app.button(tools,'Import .nc / .gcode',@()app.importGcode());b.Layout.Column=2;
            b=app.button(tools,'Export Points CSV',@()app.exportGcode());b.Layout.Column=3;
            app.GCodeStatus=app.label(tools,'Educational G00/G01/G02/G03 preview; no machine connection.',11,false);
            app.GCodeStatus.Layout.Column=4;
            e=app.panel(g,'G-CODE EDITOR (G90/G91, X/Y, I/J, F)');
            e.Layout.Row=2;e.Layout.Column=1;
            eg=uigridlayout(e,[1 1]);eg.Padding=[9 8 9 9];
            app.CodeEditor=uitextarea(eg,'FontName','Courier New','FontSize',13, ...
                'Value',{'(Example XY program)','G90','G00 X0 Y0', ...
                         'G01 X12 Y0 F120','G03 X0 Y12 I-12 J0', ...
                         'G01 X0 Y0'});
            app.GCodeAxes=app.axes(g,'G-code motion preview');
            app.GCodeAxes.Layout.Row=2;app.GCodeAxes.Layout.Column=2;
            p=app.panel(g,'INTERPRETED MOTION SEGMENTS');
            p.Layout.Row=3;p.Layout.Column=[1 2];
            s=uigridlayout(p,[1 1]);s.Padding=[8 6 8 8];
            app.GCodeTable=uitable(s,'ColumnEditable',false(1,7));
            app.GCodeTable.ColumnWidth={75 85 90 90 90 90 95};
            app.previewGcode();
        end

        function makeExportTab(app,tab)
            g=uigridlayout(tab,[2 2]);
            g.RowHeight={370,'1x'};g.ColumnWidth={'1x','1x'};
            g.Padding=[18 18 18 18];g.RowSpacing=15;g.ColumnSpacing=15;
            left=app.panel(g,'EXPORT & AUTO REPORT');left.Layout.Row=1;
            left.Layout.Column=1;
            l=uigridlayout(left,[7 1]);
            l.RowHeight={34,41,41,41,41,41,'1x'};
            b=app.button(l,'Export Professional PDF Report',@()app.exportReport(),true);
            b.Layout.Row=1;
            b=app.button(l,'Export Current Toolpath CSV',@()app.exportPath());b.Layout.Row=2;
            b=app.button(l,'Export Current Toolpath XLSX',@()app.exportPathExcel());b.Layout.Row=3;
            b=app.button(l,'Export Algorithm Comparison CSV',@()app.exportComparison());b.Layout.Row=4;
            b=app.button(l,'Export DDA Register Trace CSV',@()app.exportRegisters());b.Layout.Row=5;
            b=app.button(l,'Export G-code Preview CSV',@()app.exportGcode());b.Layout.Row=6;
            right=app.panel(g,'PROJECT FILES & SETTINGS');right.Layout.Row=1;
            right.Layout.Column=2;
            r=uigridlayout(right,[7 1]);
            r.RowHeight={37,42,42,33,36,35,'1x'};
            b=app.button(r,'Save Complete Project (.mat)',@()app.saveProject(),true);
            b.Layout.Row=1;
            b=app.button(r,'Load Project (.mat)',@()app.loadProject());b.Layout.Row=2;
            b=app.button(r,'Import Waypoint CSV / XLSX / MAT',@()app.importWaypoints());
            b.Layout.Row=3;
            q=app.label(r,'Appearance',12,true);q.Layout.Row=4;
            app.ThemeChoice=uidropdown(r,'Items',{'Dark','Light'},'Value','Dark');
            app.ThemeChoice.Layout.Row=5;
            app.ThemeChoice.ValueChangedFcn=@(~,~)app.applyTheme(app.ThemeChoice.Value);
            q=app.label(r,'MATLAB base + App Designer-style UI (no extra toolboxes)',10,false);
            q.Layout.Row=6;
            bottom=app.panel(g,'STATUS & GUIDANCE');bottom.Layout.Row=2;
            bottom.Layout.Column=[1 2];
            x=uigridlayout(bottom,[2 1]);x.RowHeight={90,'1x'};
            app.ExportStatus=app.label(x, ...
                'Select an export format. PDF includes trajectory visualization and two-algorithm metrics.',13,true);
            app.ExportStatus.WordWrap='on';app.ExportStatus.Layout.Row=1;
            q=app.label(x,[ ...
                'Input coordinates are integer grid steps, not physical machining distances. ', ...
                'PBC emits one axis pulse per cycle. The DDA may emit synchronized X/Y pulses. ', ...
                'G-code is preview-only and intentionally supports a limited ISO-style subset. ', ...
                'Use the supplied tests before publishing your results.'],12,false);
            q.WordWrap='on';q.Layout.Row=2;
        end

        function modeChanged(app)
            if isempty(app.CX),return;end
            on=strcmp(app.PathType.Value,'Circular');
            if on
                app.CX.Enable='on';app.CY.Enable='on';app.Direction.Enable='on';
            else
                app.CX.Enable='off';app.CY.Enable='off';app.Direction.Enable='off';
            end
        end
        function p=parameters(app)
            p=struct('PathType',app.PathType.Value, ...
                'Method',app.Method.Value,'Direction',app.Direction.Value, ...
                'Start',[app.X0.Value app.Y0.Value], ...
                'End',[app.X1.Value app.Y1.Value], ...
                'Center',[app.CX.Value app.CY.Value], ...
                'AnimationDelay',app.Delay.Value);
        end
        function generatePath(app)
            app.Running=false;
            try
                p=app.parameters();
                r=interpolatePath(p.PathType,p.Method,p.Start,p.End, ...
                    p.Center,p.Direction);
                app.Result=r;app.PathCursor=1;
                app.SimTable.Data=buildStepLog(r,p.Start,p.End,p.Center);
                app.plotResult();
                app.MaxErrorLabel.Text=sprintf('%.5f grid',r.info.MaxDeviation);
                app.EndErrorLabel.Text=sprintf('%.4f grid',norm(r.points(end,:)-p.End));
                app.PathLengthLabel.Text=sprintf('%.3f steps',r.info.PathLength);
                app.updatePlayback();
                app.StatusLabel.Text='Path generated; use Step or Animate.';
            catch err
                app.Result=[];
                app.StatusLabel.Text='Invalid geometry / algorithm parameters.';
                uialert(app.UIFigure,err.message,'Interpolation error');
            end
        end
        function plotResult(app)
            r=app.Result;if isempty(r),return;end
            ax=app.SimAxes;cla(ax);hold(ax,'on');
            points=[r.points;r.ideal];
            if strcmp(r.info.PathType,'Circular')
                points=[points;app.CX.Value app.CY.Value];
            end
            app.autoLimits(ax,points); % Draw X=0/Y=0 behind the toolpath.
            plot(ax,r.ideal(:,1),r.ideal(:,2),'--', ...
                'Color',[.96 .97 1],'LineWidth',1.5);
            app.SimLine=plot(ax,r.points(1,1),r.points(1,2),'-', ...
                'Color',[1 .53 .72],'LineWidth',2.5);
            plot(ax,r.points(1,1),r.points(1,2),'o', ...
                'MarkerFaceColor',[.16 .92 .85],'MarkerSize',9, ...
                'MarkerEdgeColor',[.04 .09 .13]);
            plot(ax,r.points(end,1),r.points(end,2),'s', ...
                'MarkerFaceColor',[1 .80 .38],'MarkerSize',9, ...
                'MarkerEdgeColor',[.04 .09 .13]);
            if strcmp(r.info.PathType,'Circular')
                c=[app.CX.Value app.CY.Value];
                plot(ax,c(1),c(2),'o','MarkerFaceColor',[0 .81 1], ...
                    'MarkerSize',8,'MarkerEdgeColor',[.04 .09 .13]);
            end
            app.SimMarker=plot(ax,r.points(1,1),r.points(1,2),'o', ...
                'MarkerFaceColor',[1 .53 .72],'MarkerSize',10, ...
                'MarkerEdgeColor',[1 1 1]);
            title(ax,[r.info.PathType,' • ',r.info.Method]);
            hold(ax,'off');
        end
        function autoLimits(~,ax,p)
            drawCNCXYOrigin(ax,p);
        end
        function updatePlayback(app)
            if isempty(app.Result)||isempty(app.SimLine)|| ...
                    ~isgraphics(app.SimLine),return;end
            selected=app.Result.points(1:app.PathCursor,:);
            app.SimLine.XData=selected(:,1);
            app.SimLine.YData=selected(:,2);
            app.SimMarker.XData=selected(end,1);
            app.SimMarker.YData=selected(end,2);
            app.StepLabel.Text=sprintf('%d / %d',app.PathCursor-1, ...
                size(app.Result.points,1)-1);
            app.StatusLabel.Text=sprintf('Current point (%g,%g)  •  Step %d', ...
                selected(end,1),selected(end,2),app.PathCursor-1);
        end
        function moveStep(app,increment)
            if isempty(app.Result),app.generatePath();end
            if isempty(app.Result),return;end
            app.Running=false;
            app.PathCursor=max(1,min(size(app.Result.points,1), ...
                app.PathCursor+increment));
            app.updatePlayback();
        end
        function animatePath(app)
            if isempty(app.Result),app.generatePath();end
            if isempty(app.Result)||app.Running,return;end
            app.Running=true;
            while app.Running && isvalid(app.UIFigure) && ...
                    app.PathCursor<size(app.Result.points,1)
                app.PathCursor=app.PathCursor+1;
                app.updatePlayback();
                drawnow;
                pause(app.Delay.Value);
            end
            app.Running=false;
        end
        function pausePath(app),app.Running=false;end
        function resetPath(app)
            app.Running=false;
            if isempty(app.Result),return;end
            app.PathCursor=1;app.updatePlayback();
        end
        function runComparison(app)
            app.Running=false;
            try
                p=app.parameters();
                c=compareInterpolators(p.PathType,p.Start,p.End,p.Center,p.Direction);
                app.Comparison=c;
                app.CompareTable.Data=c.Metrics;
                app.plotComparison(app.PBCPlot,c.PBC,[1 .53 .72]);
                app.plotComparison(app.DDAPlot,c.DDA,[.12 .84 1]);
                m=c.Metrics;
                app.CompareStatus.Text=sprintf( ...
                    'PBC: %d cycles, max error %.4f   |   DDA: %d cycles, max error %.4f.  CPU time varies by system.', ...
                    m.PulseCycles(1),m.MaxDeviation(1), ...
                    m.PulseCycles(2),m.MaxDeviation(2));
                app.updateErrorAnalysis();
            catch err
                app.CompareStatus.Text='Comparison failed.';
                uialert(app.UIFigure,err.message,'Comparison error');
            end
        end
        function plotComparison(app,ax,r,color)
            cla(ax);hold(ax,'on');
            app.autoLimits(ax,[r.points;r.ideal]);
            plot(ax,r.ideal(:,1),r.ideal(:,2),'--', ...
                'Color',[.86 .90 .97],'LineWidth',1.4);
            plot(ax,r.points(:,1),r.points(:,2),'-', ...
                'Color',color,'LineWidth',2);
            plot(ax,r.points(1,1),r.points(1,2),'o', ...
                'MarkerFaceColor',[.16 .92 .85]);
            plot(ax,r.points(end,1),r.points(end,2),'s', ...
                'MarkerFaceColor',[1 .80 .38]);
            hold(ax,'off');
        end
        function updateErrorAnalysis(app)
            if isempty(app.Comparison),return;end
            c=app.Comparison;ax=app.ErrorCurveAxes;
            cla(ax);hold(ax,'on');
            plot(ax,(0:numel(c.PBC.deviation)-1)',c.PBC.deviation, ...
                'Color',[1 .53 .72],'LineWidth',1.8,'DisplayName','PBC');
            plot(ax,(0:numel(c.DDA.deviation)-1)',c.DDA.deviation, ...
                'Color',[.12 .84 1],'LineWidth',1.8,'DisplayName','DDA');
            xlabel(ax,'Discrete step index');ylabel(ax,'Geometric error (grid units)');
            legend(ax,'show','Location','best');grid(ax,'on');hold(ax,'off');
            ax=app.ErrorBarsAxes;cla(ax);
            m=c.Metrics;
            vals=[m.MaxDeviation,m.MeanDeviation,m.EndpointError]';
            bar(ax,1:3,vals,'grouped');
            ax.XTick=1:3;ax.XTickLabel={'Maximum','Mean','Endpoint'};
            ylabel(ax,'Deviation (grid units)');
            legend(ax,{'PBC','DDA'},'Location','best');grid(ax,'on');
            app.ErrorInfoLabel.Text=sprintf([ ...
                'PBC: max %.4f, mean %.4f, cycles %d.   ', ...
                'DDA: max %.4f, mean %.4f, cycles %d.  ', ...
                'Linear error is perpendicular distance to the ideal infinite line; ', ...
                'circular error is radial deviation. Both reach their specified endpoints.'], ...
                m.MaxDeviation(1),m.MeanDeviation(1),m.PulseCycles(1), ...
                m.MaxDeviation(2),m.MeanDeviation(2),m.PulseCycles(2));
        end

        function useSliderDelay(app)
            app.Delay.Value=app.SpeedSlider.Value;
        end
        function syncSpeed(app)
            app.SpeedSlider.Value=app.Delay.Value;
        end

        function calculateRegisters(app)
            try
                app.Registers=ddaRegisterTrace(app.VX.Value,app.RX.Value, ...
                    app.VY.Value,app.RY.Value,app.Bits.Value,app.Cycles.Value);
                app.RegisterCursor=1;
                app.RegisterTable.Data=app.Registers.Table;
                p=app.Registers.Points;
                ax=app.RegisterAxes;cla(ax);hold(ax,'on');
                app.autoLimits(ax,p);
                plot(ax,p(:,1),p(:,2),'--', ...
                    'Color',[.85 .92 .98],'LineWidth',1.5);
                app.RegLine=plot(ax,p(1,1),p(1,2),'-', ...
                    'Color',[1 .53 .72],'LineWidth',2.3);
                app.RegMarker=plot(ax,p(1,1),p(1,2),'o', ...
                    'MarkerFaceColor',[1 .53 .72],'MarkerEdgeColor',[1 1 1]);
                hold(ax,'off');
                app.updateRegisters();
            catch err
                app.Registers=[];
                if ~isempty(app.RegisterStatus)
                    app.RegisterStatus.Text='Invalid register configuration.';
                end
                uialert(app.UIFigure,err.message,'DDA register error');
            end
        end
        function moveRegister(app,incr)
            if isempty(app.Registers),app.calculateRegisters();end
            if isempty(app.Registers),return;end
            app.RegisterCursor=max(1,min(size(app.Registers.Points,1), ...
                app.RegisterCursor+incr));
            app.updateRegisters();
        end
        function updateRegisters(app)
            if isempty(app.Registers),return;end
            p=app.Registers.Points(1:app.RegisterCursor,:);
            if ~isempty(app.RegLine) && isgraphics(app.RegLine)
                app.RegLine.XData=p(:,1);app.RegLine.YData=p(:,2);
                app.RegMarker.XData=p(end,1);app.RegMarker.YData=p(end,2);
            end
            t=app.Registers.Table;k=app.RegisterCursor;
            app.RegisterStatus.Text=sprintf( ...
                'Clock %d/%d | J_rx:%s J_ry:%s | carry:%d/%d | X:%d Y:%d', ...
                k-1,app.Registers.Cycles,t.J_rx{k},t.J_ry{k}, ...
                t.PulseX(k),t.PulseY(k),t.X(k),t.Y(k));
        end
        function importRegisters(app)
            [file,path]=uigetfile( ...
                {'*.csv;*.tsv;*.txt;*.xlsx;*.mat','DDA configuration'}, ...
                'Import binary register configuration');
            if isequal(file,0),return;end
            try
                c=readDDARegisters(fullfile(path,file));
                app.VX.Value=c.J_vx;app.RX.Value=c.J_rx;
                app.VY.Value=c.J_vy;app.RY.Value=c.J_ry;
                app.Bits.Value=c.NBits;app.Cycles.Value=c.Cycles;
                app.calculateRegisters();
            catch err
                uialert(app.UIFigure,err.message,'Register import failed');
            end
        end
        function previewGcode(app)
            try
                script=strjoin(app.CodeEditor.Value,sprintf('\n'));
                pg=parseCNCGCode(script,app.Method.Value);
                app.GCodeProgram=pg;
                app.GCodeTable.Data=pg.Table;
                ax=app.GCodeAxes;cla(ax);hold(ax,'on');
                app.autoLimits(ax,pg.Points);
                for j=1:numel(pg.Segments)
                    s=pg.Segments(j);
                    if s.IsRapid
                        plot(ax,s.Points(:,1),s.Points(:,2),'--', ...
                            'Color',[.92 .77 .4],'LineWidth',1.5);
                    else
                        plot(ax,s.Points(:,1),s.Points(:,2),'-', ...
                            'Color',[.12 .84 1],'LineWidth',1.9);
                    end
                end
                p=pg.Points;
                plot(ax,p(1,1),p(1,2),'o','MarkerFaceColor',[.16 .92 .85]);
                plot(ax,p(end,1),p(end,2),'s','MarkerFaceColor',[1 .8 .38]);
                hold(ax,'off');
                app.GCodeStatus.Text=sprintf( ...
                    '%d moves / %d plotted points / %d G00 rapid moves (preview only)', ...
                    pg.MotionSegments,pg.TotalPoints,pg.RapidSegments);
            catch err
                app.GCodeProgram=[];
                if ~isempty(app.GCodeStatus)
                    app.GCodeStatus.Text=['Error: ',err.message];
                end
                uialert(app.UIFigure,err.message,'G-code error');
            end
        end
        function importGcode(app)
            [f,d]=uigetfile({'*.nc;*.gcode;*.tap;*.txt','G-code programs'}, ...
                'Select educational G-code program');
            if isequal(f,0),return;end
            try
                t=fileread(fullfile(d,f));
                app.CodeEditor.Value=regexp(strrep(t,sprintf('\r'),''), ...
                    sprintf('\n'),'split');
                app.previewGcode();
            catch err
                uialert(app.UIFigure,err.message,'G-code import error');
            end
        end
        function exportPath(app)
            if isempty(app.Result),app.generatePath();end
            if isempty(app.Result),return;end
            app.writeTable(app.SimTable.Data,'*.csv', ...
                'toolpath_points.csv','Export interpolated toolpath');
        end
        function exportPathExcel(app)
            if isempty(app.Result),app.generatePath();end
            if isempty(app.Result),return;end
            app.writeTable(app.SimTable.Data,'*.xlsx', ...
                'toolpath_points.xlsx','Export toolpath spreadsheet');
        end
        function exportComparison(app)
            if isempty(app.Comparison),app.runComparison();end
            if isempty(app.Comparison),return;end
            app.writeTable(app.Comparison.Metrics,'*.csv', ...
                'interpolator_comparison.csv','Export algorithm comparison');
        end
        function exportRegisters(app)
            if isempty(app.Registers),app.calculateRegisters();end
            if isempty(app.Registers),return;end
            app.writeTable(app.Registers.Table,'*.csv', ...
                'dda_register_trace.csv','Export DDA register trace');
        end
        function exportGcode(app)
            if isempty(app.GCodeProgram),app.previewGcode();end
            if isempty(app.GCodeProgram),return;end
            app.writeTable(app.GCodeProgram.Table,'*.csv', ...
                'gcode_motion_segments.csv','Export G-code segments');
        end
        function writeTable(app,t,pattern,defaultName,dialogTitle)
            [file,path]=uiputfile(pattern,dialogTitle,defaultName);
            if isequal(file,0),return;end
            try
                [~,~,ext]=fileparts(file);
                if isempty(ext),file=[file,pattern(2:end)];end
                writetable(t,fullfile(path,file));
                app.setExportStatus(['Saved ',fullfile(path,file)]);
            catch err
                uialert(app.UIFigure,err.message,'Export failed');
            end
        end
        function exportReport(app)
            if isempty(app.Comparison),app.runComparison();end
            if isempty(app.Comparison),return;end
            [f,d]=uiputfile('*.pdf','Export A4 PDF analysis report', ...
                'CNC_Interpolation_Analysis_Report.pdf');
            if isequal(f,0),return;end
            [~,~,ext]=fileparts(f);
            if isempty(ext),f=[f,'.pdf'];end
            try
                p=app.parameters();
                exportCNCReport(fullfile(d,f),app.Comparison,p);
                app.setExportStatus(['PDF created: ',fullfile(d,f)]);
            catch err
                uialert(app.UIFigure,err.message,'PDF report error');
            end
        end
        function saveProject(app)
            [f,d]=uiputfile('*.mat','Save MATLAB project', ...
                'CNC_Interpolation_Project.mat');
            if isequal(f,0),return;end
            [~,~,e]=fileparts(f);if isempty(e),f=[f,'.mat'];end
            project=struct('Version',1,'Parameters',app.parameters(), ...
                'GCode',strjoin(app.CodeEditor.Value,sprintf('\n')), ...
                'Register',struct('J_vx',app.VX.Value,'J_rx',app.RX.Value, ...
                    'J_vy',app.VY.Value,'J_ry',app.RY.Value, ...
                    'NBits',app.Bits.Value,'Cycles',app.Cycles.Value), ...
                'Theme',app.ThemeChoice.Value);
            try
                save(fullfile(d,f),'project');
                app.setExportStatus(['Project saved: ',fullfile(d,f)]);
            catch err
                uialert(app.UIFigure,err.message,'Project save error');
            end
        end
        function loadProject(app)
            [f,d]=uigetfile('*.mat','Load MATLAB project');
            if isequal(f,0),return;end
            try
                entry=load(fullfile(d,f),'project');
                if ~isfield(entry,'project')||~isstruct(entry.project)|| ...
                        ~isscalar(entry.project)||~isfield(entry.project,'Version')|| ...
                        entry.project.Version~=1
                    error('Project:Format','Unsupported project MAT file or schema.');
                end
                p=entry.project.Parameters;
                % Validate geometry before touching any existing UI state.
                interpolatePath(p.PathType,p.Method,p.Start,p.End,p.Center,p.Direction);
                if ~isfield(entry.project,'Register')||~isfield(entry.project,'GCode')
                    error('Project:Format','Missing register or G-code fields.');
                end
                r=entry.project.Register;
                ddaRegisterTrace(r.J_vx,r.J_rx,r.J_vy,r.J_ry,r.NBits,r.Cycles);
                parseCNCGCode(entry.project.GCode,p.Method);
                if ~isscalar(p.AnimationDelay)||p.AnimationDelay<0||p.AnimationDelay>1
                    error('Project:Delay','Animation delay must be between 0 and 1 seconds.');
                end
                app.PathType.Value=p.PathType;app.Method.Value=p.Method;
                app.Direction.Value=p.Direction;
                app.X0.Value=p.Start(1);app.Y0.Value=p.Start(2);
                app.X1.Value=p.End(1);app.Y1.Value=p.End(2);
                app.CX.Value=p.Center(1);app.CY.Value=p.Center(2);
                app.Delay.Value=p.AnimationDelay;
                app.syncSpeed();
                app.VX.Value=r.J_vx;app.RX.Value=r.J_rx;
                app.VY.Value=r.J_vy;app.RY.Value=r.J_ry;
                app.Bits.Value=r.NBits;app.Cycles.Value=r.Cycles;
                app.CodeEditor.Value=regexp(entry.project.GCode,sprintf('\n'),'split');
                if isfield(entry.project,'Theme')&& ...
                        any(strcmp(entry.project.Theme,{'Dark','Light'}))
                    app.ThemeChoice.Value=entry.project.Theme;
                    app.applyTheme(entry.project.Theme);
                end
                app.modeChanged();app.generatePath();app.calculateRegisters();
                app.previewGcode();app.Comparison=[];app.CompareTable.Data=[];
                app.setExportStatus(['Project loaded: ',fullfile(d,f)]);
            catch err
                uialert(app.UIFigure,err.message,'Project load error');
            end
        end
        function importWaypoints(app)
            [f,d]=uigetfile({'*.csv;*.xlsx;*.mat','Waypoint file'}, ...
                'Import planned start/end/center waypoints');
            if isequal(f,0),return;end
            try
                pts=readCNCWaypoints(fullfile(d,f));
                % Import coordinates, but do not override algorithm settings.
                app.X0.Value=pts.Start(1);app.Y0.Value=pts.Start(2);
                app.X1.Value=pts.End(1);app.Y1.Value=pts.End(2);
                app.CX.Value=pts.Center(1);app.CY.Value=pts.Center(2);
                app.generatePath();
                app.setExportStatus(['Waypoints imported: ',fullfile(d,f)]);
            catch err
                uialert(app.UIFigure,err.message,'Waypoint import failed');
            end
        end
        function setExportStatus(app,content)
            if ~isempty(app.ExportStatus)&&isvalid(app.ExportStatus)
                app.ExportStatus.Text=content;
            end
        end
        function openClassic(app)
            % Reuse the Classic window that launched PRO, if available.
            if isempty(app.ClassicApp) || ~isvalid(app.ClassicApp)
                app.ClassicApp=CNCInterpolationApp(app);
            elseif ~isgraphics(app.ClassicApp.UIFigure)
                app.ClassicApp=CNCInterpolationApp(app);
            else
                app.ClassicApp.UIFigure.Visible='on';
                app.ClassicApp.UIFigure.WindowState='normal';
            end
        end
        function applyTheme(app,themeName)
            dark=strcmp(themeName,'Dark');app.Dark=dark;
            if dark
                bg=[.065 .090 .145];panel=[.105 .15 .225];
                fg=[.92 .96 1];axesBg=[.085 .13 .19];
            else
                bg=[.91 .94 .97];panel=[.98 .99 1];
                fg=[.08 .16 .27];axesBg=[1 1 1];
            end
            if isempty(app.UIFigure)||~isvalid(app.UIFigure),return;end
            app.UIFigure.Color=bg;
            for k=1:numel(app.ThemePanels)
                obj=app.ThemePanels{k};
                if isvalid(obj)
                    obj.BackgroundColor=panel;obj.ForegroundColor=fg;
                end
            end
            for k=1:numel(app.ThemeAxes)
                ax=app.ThemeAxes{k};
                if isvalid(ax)
                    ax.Color=axesBg;ax.XColor=fg;ax.YColor=fg;
                    ax.GridColor=[.55 .62 .7];
                    ax.Title.Color=fg;
                    % Keep the manually drawn X=0/Y=0 axes readable in
                    % either theme, including the '0', X and Y labels.
                    originGraphics=findall(ax,'-regexp','Tag', ...
                        '^CNC(Zero|Origin|Direction)');
                    for m=1:numel(originGraphics)
                        originGraphics(m).Color=fg;
                    end
                end
            end
            for k=1:numel(app.ThemeLabels)
                obj=app.ThemeLabels{k};
                if isvalid(obj)
                    % Keep the six legend colors in both themes.
                    if strcmp(obj.Text,'- -  Command path')
                        obj.FontColor=fg;
                    elseif ~any(strcmp(obj.Text, ...
                            {'---  Interpolated path','●  Start S', ...
                            '■  End E','●  Center C','●  Current point'}))
                        obj.FontColor=fg;
                    end
                end
            end
            % Layout backgrounds follow the selected theme as well.
            objects=findall(app.UIFigure);
            for k=1:numel(objects)
                obj=objects(k);
                if isa(obj,'matlab.ui.container.GridLayout')
                    obj.BackgroundColor=bg;
                end
            end
        end
    end

    methods (Access = public)
        function app=CNCProfessionalDashboard(existingClassic)
            app.createComponents();
            if nargin >= 1 && ~isempty(existingClassic) && ...
                    isa(existingClassic,'CNCInterpolationApp') && ...
                    isvalid(existingClassic)
                app.ClassicApp=existingClassic;
            end
            registerApp(app,app.UIFigure);
            if nargout==0,clear app;end
        end
        function delete(app)
            app.Running=false;
            if ~isempty(app.UIFigure)&&isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
