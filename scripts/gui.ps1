param([string]$cmds = "C:\clo_jobs\gui_cmds.txt")
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class U {
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(int f,int x,int y,int d,int e);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 public delegate bool EP(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EP cb, IntPtr l);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out int p);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int hh,bool r);
 public static System.Collections.Generic.List<string> L = new System.Collections.Generic.List<string>();
 public static void List(){ L.Clear(); EnumWindows((h,l)=>{ if(IsWindowVisible(h)){ var sb=new System.Text.StringBuilder(256); GetWindowText(h,sb,256); int p; GetWindowThreadProcessId(h,out p); RECT r; GetWindowRect(h,out r); L.Add(h.ToInt64()+"|"+p+"|"+sb+"|"+r.L+","+r.T+","+r.R+","+r.B);} return true;}, IntPtr.Zero); }
}
"@
[U]::SetProcessDPIAware() | Out-Null
$log = "C:\clo_jobs\gui.log"
"start $(Get-Date)" | Out-File $log
foreach ($line in Get-Content $cmds) {
  $p = $line -split ' ',2; $op=$p[0]; $arg = if ($p.Count -gt 1) {$p[1]} else {""}
  try {
  switch ($op) {
   "focus" { $pr = Get-Process | ? { $_.MainWindowTitle -like "*$arg*" -or $_.ProcessName -like "*$arg*" } | ? { $_.MainWindowHandle -ne 0 } | select -First 1
             if ($pr) { [U]::ShowWindow($pr.MainWindowHandle,3)|Out-Null; [U]::SetForegroundWindow($pr.MainWindowHandle)|Out-Null; "focus $($pr.MainWindowTitle)" | Out-File $log -Append } else { "nofocus $arg" | Out-File $log -Append } }
   "click" { $xy=$arg -split ','; [U]::SetCursorPos([int]$xy[0],[int]$xy[1]); Start-Sleep -m 100; [U]::mouse_event(2,0,0,0,0); [U]::mouse_event(4,0,0,0,0) }
   "dclick" { $xy=$arg -split ','; [U]::SetCursorPos([int]$xy[0],[int]$xy[1]); 1..2 | % { [U]::mouse_event(2,0,0,0,0); [U]::mouse_event(4,0,0,0,0); Start-Sleep -m 60 } }
   "keys" { [System.Windows.Forms.SendKeys]::SendWait($arg) }
   "paste" { Set-Clipboard -Value (Get-Content $arg -Raw); [System.Windows.Forms.SendKeys]::SendWait("^v") }
   "clip" { Set-Clipboard -Value $arg }
   "windows" { [U]::List(); [U]::L | Out-File $log -Append }
   "max" { $h=[IntPtr][long]$arg; [U]::ShowWindow($h,3)|Out-Null; [U]::SetForegroundWindow($h)|Out-Null }
   "min" { [U]::ShowWindow([IntPtr][long]$arg,6)|Out-Null }
   "show" { $h=[IntPtr][long]$arg; [U]::ShowWindow($h,9)|Out-Null; [U]::SetForegroundWindow($h)|Out-Null }
   "raise" { $h=[IntPtr][long]$arg; [U]::SetForegroundWindow($h)|Out-Null }
   "front" { $h=[IntPtr][long]$arg; [U]::ShowWindow($h,9)|Out-Null; [U]::MoveWindow($h,200,100,1400,850,$true)|Out-Null; [U]::SetForegroundWindow($h)|Out-Null }
   "sleep" { Start-Sleep -m ([int]$arg) }
   "shot" { $b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bm=New-Object System.Drawing.Bitmap $b.Width,$b.Height; $g=[System.Drawing.Graphics]::FromImage($bm); $g.CopyFromScreen($b.Location,[System.Drawing.Point]::Empty,$b.Size); $bm.Save($arg,[System.Drawing.Imaging.ImageFormat]::Png); "shot $($b.Width)x$($b.Height)" | Out-File $log -Append }
  }} catch { "err $line : $_" | Out-File $log -Append }
}
"end" | Out-File $log -Append
