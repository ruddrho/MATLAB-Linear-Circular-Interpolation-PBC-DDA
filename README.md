# CNC Interpolation Studio PRO

**Author:** [RUDDRHO MOLLIK](https://github.com/ruddrho)  
**GitHub profile:** https://github.com/ruddrho

**MATLAB App Designer-style application** for teaching, visualizing, comparing, and reporting two-dimensional CNC pulse interpolation. Created for a university course / engineering portfolio.

- **Project type:** MATLAB application + pure MATLAB algorithms
- **Important:** Educational simulation, **not a hardware CNC controller**.

## Start

Download/extract the repository, open its root folder in MATLAB, then execute:

```matlab
run_app
```

`run_app` opens **Classic View by default** (Linear / Point-by-Point Comparison,
all coordinates at `0`). The top header now matches the PRO interface: **CNC INTERPOLATION STUDIO PRO**,
a centered module summary and an **Open PRO View** button at the top-right.
The button opens the full tabbed PRO dashboard while keeping the Classic
simulation, results, and six-item legend intact.

You can also start either interface explicitly:

```matlab
run_app('classic')
run_app('pro')
```

To directly launch the original app (preserved in this repository):

```matlab
CNCInterpolationApp
```

To launch the new workspace without the wrapper:

```matlab
CNCProfessionalDashboard
```

Test the pure algorithms without starting the GUI:

```matlab
run_tests
```

Run the optional PDF rendering test on a computer with graphical MATLAB:

```matlab
run_tests(true)
```

To verify the actual GUI defaults and slider interaction on a MATLAB desktop, run:

```matlab
addpath('tests');
test_ui_defaults_gui
% Optional: verify Classic-first launch and the PRO navigation button
test_startup_navigation_gui
```

The app is a **programmatic App Designer-style `matlab.apps.AppBase` class (`.m`)**, not a binary `.mlapp` file. All UI source can be edited using the MATLAB Editor. No Statistics, Optimization, Report Generator, or other MATLAB toolboxes are required for the supplied algorithms and UI (spreadsheet import/export depends on the installed MATLAB platform and release).

## Interpolation unit-test regression fix

The algorithm test now uses `diff(r.points,1,1)` instead of
`diff(r.points)`. MATLAB's default `diff` dimension is the first
**non-singleton** dimension, so on a one-row, two-column coordinate array
(a zero-length line such as `[3 3]` to `[3 3]`) plain `diff` subtracts
X from Y rather than computing successive XY pulse displacements.
This caused the previous `run_tests` failure at `test_interpolation`
line 18 even though the zero-length path was valid. The updated test
explicitly verifies zero displacement and a single output point for
both PBC and DDA without altering the interpolation algorithms.

Run from the project root:

```matlab
clear functions
rehash
run_tests
```

If MATLAB resolves another older version of the files, run
`which test_interpolation -all` and `which run_tests -all` to check the
paths, then set MATLAB's Current Folder to this release.

## Header startup fix

Fixed MATLAB startup error: `Unable to set the 'Position' property of class 'GridLayout' because it is read-only.` The Classic header now uses a **positioned `uipanel`** containing a **three-column `uigridlayout`**, rather than assigning `Position` directly to the grid. Existing header title, subtitle, and **Open PRO View** button are unchanged.

To check the fix on MATLAB desktop:

```matlab
run_app
addpath('tests');
test_startup_navigation_gui
```

## Professional workspace

| Tab | Functionality |
| --- | --- |
| **Simulation** | Linear/circular interpolation, PBC/DDA choice, CW/CCW, coordinates, center, animation delay + speed slider, playback with Play/Pause/Step +/-/Reset, seven-column step log, fixed six-key graph legend |
| **PBC vs DDA** | Run both methods on identical geometry, independent plot for each, pulse cycles, maximum and mean geometric error, endpoint error, path length, illustrative CPU evaluation time, export comparison CSV |
| **Error analysis** | Step-by-step geometric deviation curves and grouped maximum/mean/endpoint error bars for both methods |
| **Binary register lab** | Independent X/Y fixed-width DDA registers (`J_vx`, `J_rx`, `J_vy`, `J_ry`), N-bit accumulator, overflow/carry pulses, previous/next clock, trajectory, imported configs and CSV trace export |
| **G-code preview** | Restricted G00/G01/G02/G03 with absolute/relative XY (G90/G91), incremental center offsets I/J, modal movements, file import, line-numbered segment table, preview and export. This is **not executable machine G-code**. |
| **Reports & Project** | A4 PDF comparison report with timestamp and comparison metrics, path CSV/XLSX export, DDA trace CSV, G-code CSV, `.mat` project save/load, waypoint CSV/XLSX/MAT import, dark/light theme |

**Classic View is the startup interface.** Classic now shares the three-part
PRO-style top header: title on the left, module descriptions in the center,
and **Open PRO View** at the top-right. The **RUN METRICS** panel is dedicated
to pulse cycles, path length, geometric error, circular sweep and status.
The tabbed dashboard retains **Open Classic View** in the corresponding
header position. Navigation reuses an existing companion window where possible;
the original Classic six-key legend, DDA Register Lab, and animation controls
are preserved.

## Default view & PRO navigation

- `run_app` launches **Classic View**. You do not need to call
  `CNCInterpolationApp` separately.
- Click **Open PRO View** in the **top-right header** of Classic View
  to open the full Professional Dashboard; the four run metrics stay in place.
- From PRO, use **Open Classic View** to return to the original interface.
- `run_app('pro')` is available for users who prefer to start in the
  tabbed dashboard.
- The numerical results, interpolation methods, default coordinates,
  step tables, origin axes, themes, PDF reports, and import/export logic
  are unchanged.

## Cartesian zero origin (X=0 / Y=0)

- The main plot in **Classic View** and all XY plots in the **Professional Dashboard** now show a strong horizontal **Y=0 (X axis)** and vertical **X=0 (Y axis)** line crossing at the true origin **(0,0)**.
- The origin is labeled **0**, and the positive **X** and **Y** directions are labeled directly on the graph, matching the classroom reference display. The zero reference axes are drawn behind the commanded and interpolated paths.
- The display limits remain symmetric around zero in both directions, including for all-positive or all-negative toolpaths. Blank startup plots also show the centered origin, even when all coordinate inputs are zero.
- Axis lines and labels adapt to Light/Dark themes. No interpolation geometry, pulses, or default coordinate values were changed.

## Interface defaults and slider readability

- On first launch, **all six geometry fields start at `0`** in both the
  Professional Dashboard and the Classic View: Start X/Y, End X/Y, Center X/Y.
- **Startup dropdown defaults:** Path type **Linear**, Algorithm **Point-by-Point Comparison**
  in both Professional Dashboard and Classic View. All six coordinates default
  to **0**, and paths are not generated automatically at startup.
- Circle-only direction and center controls are disabled in the Professional
  Dashboard when Linear is selected; selecting Circular enables them.
  A circular path requires valid geometry. To try one, select Circular and
  enter Start `(12,0)`, End `(0,12)`, Center `(0,0)`, or import
  `examples/waypoints_circular.csv`.
- The animation delay slider is labeled **0, 0.25, 0.50, 0.75, 1.00** seconds
  using theme-aware high-contrast text, instead of low-contrast built-in
  slider labels. It remains linked to the numeric delay field.
- Opening saved projects or importing waypoint files restores their
  specified coordinates, rather than keeping the startup zero values.

## Input conventions

- All path coordinates and arc centers are **integer grid pulses**, not millimeters.
- For circular interpolation, both endpoints must lie on **exactly the same integer-grid radius** around the specified center.
- Circular mode accepts CW and CCW; equal start/end points command a full revolution.
- PBC linear: one X or Y pulse per update; DDA linear: X and Y pulses can occur on the same clock. **Pulse cycles are not directly equivalent workloads across methods.**
- Geometric error for a line is perpendicular distance to the infinite commanded line; for an arc it is absolute radial deviation from the commanded circle. These are **not** controller-following or servo errors.
- CPUTimeMs is a single evaluation time measured by `tic/toc`; do **not** interpret it as CNC machine execution time or a scientific benchmark.
- Binary DDA register lab is an **independent fixed-width teaching example** rather than the internal state of the circular geometric DDA algorithm.

## Data imports

### DDA register configuration

See `examples/dda_registers_example.csv`:

```csv
J_vx,J_rx,J_vy,J_ry,NBits,Cycles
101,000,011,000,3,8
```

Binary values must be digit strings; spreadsheet cells should be formatted as **text** if leading zeroes matter. This gives five X pulses and three Y pulses over eight clocks.

### XY waypoints

See `examples/waypoints_circular.csv`:

```csv
X0,Y0,X1,Y1,CX,CY
12,0,0,12,0,0
```

A MAT waypoint file must contain a scalar `waypoints` struct with `Start`, `End`, `Center` as numeric 1-by-2 vectors.

### G-code program

See `examples/demo_program.gcode`:

```gcode
G90
G00 X0 Y0
G01 X12 Y0 F120
G03 X0 Y12 I-12 J0
G01 X0 Y0
```

Full subset, semantics, and limitations are described in [`docs/GCODE_SUBSET.md`](docs/GCODE_SUBSET.md).

## Project structure

```text
CNC_Interpolation_Studio_Pro/
├── run_app.m                       # Launch Classic by default; ('pro') optional
├── CNCProfessionalDashboard.m      # Tabbed responsive AppBase UI
├── CNCInterpolationApp.m           # Preserved original AppBase UI
├── drawCNCXYOrigin.m               # Centered zero axes and origin labeling
├── interpolatePath.m               # Four pulse interpolation combinations
├── compareInterpolators.m          # PBC vs DDA metrics
├── buildStepLog.m                  # Iteration/decision log
├── ddaRegisterTrace.m              # N-bit 2-axis accumulator register model
├── readDDARegisters.m              # Import binary configurations
├── readCNCWaypoints.m              # Import XY geometry
├── parseCNCGCode.m                 # Restricted G-code interpreter
├── exportCNCReport.m               # Printable one-page PDF report
├── run_tests.m                     # Headless test entry point
├── tests/                          # Algorithm and UI smoke tests
├── examples/                       # Ready-to-import sample inputs
├── docs/                           # Algorithm and G-code notes
├── .github/workflows/              # MATLAB CI workflow
└── LICENSE
```

## Public GitHub release

This edition removes personal identification inputs from both the Professional Dashboard and Classic View. Fresh `.mat` project files store only simulation settings, registers, G-code, and theme; generated PDF reports contain analysis and timestamps without personal information. Older project files with extra legacy metadata can still be loaded; the unneeded legacy fields are ignored and are not copied into new saves. The `.gitignore` excludes local `.mat` and `.pdf` files by default.

## GitHub publishing

In a terminal, from the unzipped project directory:

```bash
git init
git add .
git commit -m "Release CNC Interpolation Studio PRO"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/cnc-interpolation-studio-pro.git
git push -u origin main
```

Create the empty GitHub repository first; replace `YOUR_USERNAME` with your own username. The included GitHub Actions workflow requires MATLAB availability through `matlab-actions`; if you cannot run CI in your account, run `run_tests` locally.

## Compatibility and verification

Target: **MATLAB R2022b or newer** with standard App Designer UI components (`uifigure`, `uigridlayout`, `uitabgroup`, `uiaxes`) and base MATLAB functions. The app was authored in a non-MATLAB environment, so **GUI runtime and PDF output are not certified**; run `run_tests` and open the UI in your MATLAB installation to confirm platform/release compatibility.

## License

MIT, see `LICENSE`.

## Matching Classic / PRO header

Classic starts with the same three-column top navigation style as PRO:

- Left: **CNC INTERPOLATION STUDIO PRO**
- Center: **PBC / DDA · 2D Toolpaths · Register Lab · G-code · Reports**
- Right: **Open PRO View** in Classic; **Open Classic View** in PRO

The PRO switch was moved out of the metrics panel, restoring room for all
four run statistics. Start view and interpolation defaults are unchanged.
