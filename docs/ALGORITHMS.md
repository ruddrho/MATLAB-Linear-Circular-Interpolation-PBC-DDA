# Algorithm design and metric definitions

## Point-by-point comparison (PBC)

For a line from `S` to `E` with `|Δx| = a`, `|Δy| = b`, the comparator uses the signed decision value `F = x_along*b - y_along*a`. The chosen axis takes one unit pulse per update. For a circular arc, the comparator checks candidate cardinal pulses in the tangent direction and chooses a low radial squared-error candidate while tracking angular progress.

## Digital Differential Analyzer (DDA)

The linear DDA accumulates the integer magnitudes `a` and `b` against a clock modulus `N = max(a,b)` and emits one or two axis pulses on each clock. Circular DDA uses small rotation increments in the plane, normalized to avoid accumulating radius drift, and rounds each tick to the integer pulse grid. Thus circular DDA and the fixed-width binary register lab are **related pedagogical concepts but not identical implementations**.

## Independent classroom register model

For `NBits=N`, modulus `M = 2^N`. Each step for each axis computes `sum = J_r + J_v`, emits `carry = (sum >= M)` and stores `J_r = mod(sum, M)`. With `N=3`, `J_vx=101`, `J_vy=011`, initial remainders `000`, the accumulated total after eight ticks is `(5,3)`.

## Measured quantities

- **PulseCycles:** Number of returned discrete path transitions. For PBC this is one-axis-per-update; DDA may pulse both axes in a cycle.
- **PathLength:** Sum of Euclidean lengths of the discrete path segments.
- **MaxDeviation / MeanDeviation:** Arithmetic maximum/mean of sample deviations; not a machine-controller tracking error.
- **EndpointError:** Euclidean distance between last returned point and specified endpoint, normally zero by algorithm design.
- **CPUTimeMs:** Wall-clock time for one algorithm function call measured by `tic/toc`. Results are unstable across CPU and OS configurations and should not be used as standalone performance conclusions.

## Limitations

Integer-pulse simulations are illustrative. Motion planning on real hardware requires acceleration limits, controller cycle guarantees, servo dynamics, unit conversion, collision checks, and machine safety interlocks, none of which are present here.
