# CLO3D automation on the tower (CLO 2026.1.382)

## Start of session
1. `schtasks /run /tn "Open CLO"` (interactive, signed-in user). Wait about 40 s.
2. `windows` shows a `Dialog` (subscription Notice): raise it, tick "Don't show again", click OK.
3. Edit > Python Script in ONE gui run (a menu closes between runs): click (110,32), then (132,240) on a maximised 1920x1080 window). A WELCOME window
   also pops up: tick "Don't Show Again" and close it.
4. `windows` again: the smaller `CLO Standalone OnlineAuth` window is the editor. `front <hwnd>` puts it at
   200,100 at 1400x850, so the editor text sits at (840,360) and Run (the triangle) at (288,148).
5. Put the editor hwnd in `E=` and the main window hwnd in `M=` at the top of `runjob.sh`.

## Per job (runjob.sh)
- `max M`, then File (70,32) > New Project (96,60). If a third CLO window appears, it's the "File not saved" prompt:
  raise it and click No (964,601). The prompt doesn't appear when the scene was just exported.
- Paste `chk.py` and run it. It writes the pattern count to `C:\clo_jobs\chk.txt`, which must be 0.
- Paste the job script, click Run, then `min E` so the main window and console stay visible.

## API facts found by probing (fix scripts to these)
- `import_api.ImportAvatar(path, ApiTypes.ImportExportOption())`. A single-arg call raises TypeError.
- `ImportOBJ(path, option)`: ImportObjectType 0 = avatar, 2 = garment patterns (traced), 1 = non-pattern
  object, 3/4 = False.
- `fabric_api.AssignFabricToPattern(fabricIdx, patternIdx, side[, colorway])`: 3 or 4 ints, never None.
- `SetFabricPBRMaterialBaseColor(fabric, colorway, r, g, b, a)` (floats 0-1).
- `utility_api.SetBackgroundColorForExportRenderingImage(r, g, b, a)`.
- `pattern_api.CreatePatternWithPoints([(x, y, type), ...])` needs the full outline (3-tuples). One point means
  the input data collapsed.
- `SetArrangementShapeStyle(idx, str)`. `utility_api.NewProject()` exists. `export_api.GetAvatarCount`
  (not utility_api). Missing: `GetPatternLineCount`, `GetCLOVersion`, `GetCustomViewInformation`.
- `ExportTurntableImages(8)` (one arg) works. The 5-arg form returns []. Output is RGBA with a transparent
  background in the CLO temp dir.
- `SetRenderImageVideoProperties` needs a `Marvelous::RenderImageVideoOptions`, not a JSON string. colorHex
  there doesn't change the turntable.

## Stalls seen
| Symptom | Cause | Fix |
|---|---|---|
| Screen shows only the editor, nothing runs | paste path eaten by `\c` | `printf %s` for paths |
| `run.sh` returns instantly, no screenshot | stale `gui.log` with `end` | delete it before each run |
| GUI task never logs past `start` | `windows` sent while a script runs | don't enumerate during a job |
| Job "running" 10+ min, CLO CPU flat | modal "Information" dialog | `unstick.sh` / click OK at (961,600) |
| Only the jacket runs, then QUEUE EMPTY | `queue.txt` missing | check it after copying |
| Job runs 15+ min, CPU creeping not flat | CLO stuck in a long loop | TIMEOUT, then `recover.sh` |
| "Autosave Recovery" on screen | CLO was killed last time | click No (1028,600); `recover.sh` does it |
| Nothing GUI works after reboot | no user signed in | ask the owner to sign in |
