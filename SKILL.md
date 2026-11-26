---
name: tower-render
description: Use for any job on the owner's tower (the tower, RTX 4090, Windows + Ubuntu) - Blender renders, CLO3D batch scripts, TouchDesigner, the idle server-console screen, moving job files to and from it, and reboots. It replaced GarageFarm (25 Nov 2026). Lists the routes that work unattended and every trap that cost time.
metadata:
  author: Alican Rowe (@alicanrowe)
---

# the tower: unattended renders and CLO batches

The tower sits away from the Mac on its own Wi-Fi. Reach it over Tailscale from the Mac:
`ssh server-win-ts` (Windows, cmd shell, signed in as the desktop user) and `ssh server-ubuntu-ts` (Ubuntu). Windows is the
GRUB default. Scripts live in `scripts/` here and on the tower in `C:\clo_jobs\` and `C:\console\`.

## Standing rules (from the owner)
- **Never idle on the Windows desktop.** Idle = the black server console (`C:\console\console.html`, Edge kiosk,
  IBM Plex Mono Light, IKIYA green `#1D847E` on black, status from `stat.ps1`). Bring it to the front after every
  job (`scripts/console.sh`). the owner: "i want it to look like a server not just a pc on wheels".
- **Never reboot mid-day without asking.** Windows has no autologon. After a reboot it waits at sign-in and
  nothing that needs the desktop (CLO, TD, the console) can run until the owner signs in. A plain restart lands in
  Windows, not Ubuntu.
- Renders go here, never on the Mac, and no longer to GarageFarm. Don't touch GarageFarm jobs.
- Every frame rendered here for a reel, post or page is finished to the studio look guide (design-taste `references/studio-look.md`): grade + unify, tags, fixed logo, the crop ending (studio.ending crop; its last frame is the grid cover). Render clean plates (no baked type) and hold the final camera move to rest so the finish pass has a clean tail.
- CLO renders use the white mannequin (`Avatar/Mannequin/MV2.1_Mannequin.avt`), never a realistic avatar.

## Getting files onto the tower
- Project-library reads cap at **25 MB per call and about 16 MB per response**. Ask the sending thread for parts
  of **12 MB or less** (`split -b 12m f f.part_` plus MD5SUMS). Rejoin with `cat f.part_* > f` and check the md5
  before you use it. A 25 MB "part" fails, and so does a whole 48 MB zip.
- Drive folders sync to the Mac (`~/Library/CloudStorage/GoogleDrive-*/My Drive/...`), so they're the fastest route
  for big inputs and outputs. Copy a file locally before you scp it (Drive placeholders stall at 0 bytes).
- Upload results with SendUserFile. It can't write into subfolders, so zip each job folder under a unique name
  (`p3out_<job>.zip`). Send at most about 10 files per call. A 429 means wait a moment, then resend only the failed
  ones.

## Blender renders (SYSTEM scheduled task, no desktop needed)
1. Put the files in `C:\Renders\<job>\`, check the md5s, and write a `.cmd` that logs `start`/`done` lines to `run.log`.
2. `schtasks /create /tn <Job> /tr C:\Renders\<job>\run.cmd /sc once /st 00:00 /ru SYSTEM /f` then `schtasks /run`.
3. Use the exact Blender the brief names (`C:\Blender\blender-4.2.3-windows-x64`, `-5.2.2`, `-5.3.0`). Keep the
   brief's seed and adaptive-sampling settings.
4. Chain jobs by waiting on the previous `run.log` line. Use a unique marker: `findstr "done stay"` also matched
   `done stay_orbit`. Note that `%date% %time%` inside a `for` loop expands once.
5. Run the brief's test frame first and look at it. Then run the full range. Then zip the frames to the Drive folder
   the brief names.
Timings on the 4090: Imago 1080x1920 OptiX 5.0 s/frame; Stay 9.7 s/frame; Nave v2 256 spp 15 s/frame.

## CLO3D batches (needs the signed-in desktop session)
CLO's Python only runs inside the GUI, so `scripts/gui.ps1` drives it. It runs as the interactive task `GUI`
(the signed-in user, `/it`) and reads `C:\clo_jobs\gui_cmds.txt`. Ops: `click x,y`, `keys`, `paste <file>`, `windows`,
`front/raise/show/min/max <hwnd>`, `shot <png>`. `run.sh` sends one command file and fetches the screenshot.
`runjob.sh` does New Project, checks the scene is empty, pastes the script, runs it and minimises the editor.
`dojob2.sh` runs one job and waits for a new `status.txt` line. `round.sh <tag>` runs the whole queue, fetches,
composites the turntables onto white and zips. `unstick.sh` clicks away modal dialogs.
Full details and traps: `references/clo-automation.md`. Short list:
- After CLO starts, dismiss the subscription Notice and the WELCOME dialog. Python Editor (Edit > Python Script)
  opens BEHIND the main window: use `windows` then `front <hwnd>`. Window handles change on every launch, so
  update `E`/`M` in `runjob.sh`.
- **Never send `windows` while a CLO script is running** (EnumWindows hangs on CLO's busy thread).
- **Modal CLO dialogs stop the batch** (for example "patterns can not be remeshed due to complex shapes").
  Run `unstick.sh` alongside every round, and ask the script owner to avoid calls that raise them.
- In zsh, `echo` and `printf` eat `\c` in Windows paths (`C:\clo_jobs` turns into `C:`). Pass paths as
  `printf ... %s`.
- Delete `gui.log` before each run, or a stale `end` line makes `run.sh` return early.
- Check that `queue.txt` really exists after the copy. Without it `build_all.py` only runs the jacket.
- Turntables from `ExportTurntableImages(8)` are **transparent RGBA, not black**. Composite onto white
  (`round.sh` does this). They land in CLO's temp folder as `output*.png` and get overwritten per job.
- **A job can hang without a dialog** (07-fret-jacket-r3: no output for 40 min, CLO CPU creeping, not flat, so
  `unstick.sh` never fired). `dojob2.sh` now gives up after 15 min and prints TIMEOUT. `round.sh` then runs
  `recover.sh`, which marks the job FAILED, kills CLO, relaunches it, answers **Autosave Recovery** with No
  (1028,600), reopens the Python Editor and writes the new E/M handles into `runjob.sh`. Up to 3 recoveries a round.
- **Every CLO kill leaves an "Autosave Recovery" prompt on the next launch.** Always click No. the owner saw this one
  on the tower screen before the operator did. Never kill CLO without running the full `recover.sh` sequence.
- Timings: jackets 15-60 s, boots 1-9 min, 20-piece round 32-50 min.

## Storage
ZFS pool `vault` (photos/docs/Mac backups) is on one T7 (the "test (ai)" sticker). The T5 also carries a
ZFS member partition, but whether the mirror is ONLINE again needs `zpool status vault` from Ubuntu (a
`grub-reboot` into Ubuntu, only with the owner's OK). The "Renders" T7 is APFS, isn't in any pool,
and Windows can't read it. Never reformat any disk without the owner's OK and a confirmed backup.

## Keep improving
When a run stalls or a step wastes time, add the cause and the fix here (and to the scripts) in the same session,
then publish. Add real durations to the ETA skill's baselines.

## Excuses that don't count
| The excuse | What to do instead |
|---|---|
| "Quick reboot to check something" | Ask the owner first. A reboot strands the desktop at sign-in. |
| "The turntables are black, fix CLO settings" | They're transparent. Composite onto white. |
| "It's just slow" | Check whether CLO CPU is flat. A flat CPU means a modal dialog: screenshot it and clear it. |
| "Fetch the whole zip" | Over 12 MB, ask for split parts. |
