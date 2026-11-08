# Supported educational G-code subset

The G-code tab is a **2D motion preview, not a real CNC interpreter or machine controller**. Never send the preview output directly to CNC equipment.

| Command | Meaning in this app |
|---|---|
| `G00` (`G0`) | Rapid motion, drawn as a straight dashed move (no timing/feed model) |
| `G01` (`G1`) | Interpolated straight line using the currently selected PBC or DDA method |
| `G02` (`G2`) | Clockwise circular interpolation |
| `G03` (`G3`) | Counterclockwise circular interpolation |
| `G90` | Absolute XY target coordinates (default) |
| `G91` | Relative XY target displacement |
| `X`, `Y` | Axis values; omitted coordinate remains unchanged |
| `I`, `J` | **Incremental offset from arc start to center**, regardless of G90/G91 |
| `F` | Accepted as annotation but not simulated |
| `N` | Optional program line identifier, ignored |

Parenthesized `(comment)` and `; comment` comments are ignored. Motion mode is modal between lines; G90/G91 may share a line with a motion command.

## Geometry requirements

- Coordinates and center offsets must resolve to integers.
- The arc radius from `start` to `center` must **exactly** match the radius from `end` to `center`.
- Radius must be at least 2 grid units for an interpolated circular path.
- A same-point arc forms a full revolution if G02/G03 is explicitly set.
- Maximum 500 motion segments and 100,000 preview points.

The parser intentionally does **not** support real CNC functionality like tool compensation, work offsets, machine limits, M codes, canned cycles, cutter/feed scheduling, alarms, spindle control, or real-time collision avoidance. Unsupported codes return an informative error rather than guessing their meaning.
