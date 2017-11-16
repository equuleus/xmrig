# xmrig.cmd
Windows Batch Script for automated elevating administartor permissions (VBScript) and start XMRig (https://github.com/xmrig/xmrig), XMRig NVIDIA (https://github.com/xmrig/xmrig-nvidia) or XMRig AMD (https://github.com/xmrig/xmrig-amd).

Silent start/stop with available parameters:

  "xmrig.cmd CPU START",

  "xmrig.cmd CPU STOP",

  "xmrig-proxy.cmd NVIDIA START",

  "xmrig.cmd NVIDIA STOP",

  "xmrig-proxy.cmd AMD START",

  "xmrig.cmd AMD STOP".
    

AMD fix for driver (HBCC start problem) included (using "devcon.exe").


If you run it without any params (and "ALLOW_MANUAL_SELECT" set to "true") you can manually input and select what ever you want to run.


If miner ("xmrig.exe", "xmrig-nvidia.exe" or "xmrig-amd.exe" file) selected and already started, it will be automatically closed (killed process).


Don't forget to put exe files to subfolders:
File "xmrig.exe" to "CPU" folder (if you want to use "CPU"), file "xmrig-nvidia.exe" to "NVIDIA" folder (if you want to use "NVIDIA") and "xmrig-amd.exe" to "AMD" folder (if you want to use "AMD").


Of course, change "WALLET", "ID", "EMAIL", "PROGRAM_CPU_PARAMETERS", "PROGRAM_NVIDIA_PARAMETERS", "PROGRAM_AMD_PARAMETERS", "PROGRAM_CPU_DIFF", "PROGRAM_NVIDIA_DIFF" and "PROGRAM_AMD_DIFF" in a CMD-file to your personal settings at your choice. Good luck!


No one known bug currently.
