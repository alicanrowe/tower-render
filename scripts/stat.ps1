while ($true) {
 try {
  $g = (& nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits) -split ',\s*'
  $st = @(Get-Content C:\clo_jobs\out\status.txt -EA 0)
  $last = if ($st.Count) { ($st[-1] -replace '^\w+ \w+ +\d+ ([\d:]+) \d{4} ','$1  ').Trim() } else { '' }
  $busy = @(Get-Process blender -EA 0).Count
  $q = if ($busy) { 'rendering (blender)' } elseif ($last -match 'QUEUE EMPTY') { 'idle' } else { 'clo queue running' }
  $o = @{ os="windows 11 $([char]0xB7) rtx 4090 $([char]0xB7) tailscale up"; gpu=$g[0]; load="$($g[1]) %"; temp="$($g[2]) $([char]0xB0)C"; vram="$($g[3]) / $($g[4]) MiB"; queue=$q; last=$last; time=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
  [IO.File]::WriteAllText("C:\console\status.js", "window.S=" + ($o | ConvertTo-Json -Compress) + ";", (New-Object Text.UTF8Encoding $false))
 } catch {}
 Start-Sleep 5
}
