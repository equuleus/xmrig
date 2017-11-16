# xmrig.cmd
Windows Batch Script for automated start XMRig and XMRig NVIDIA (https://github.com/xmrig/xmrig & https://github.com/xmrig/xmrig-nvidia) with parameters

Run with available parameters: "xmrig.cmd CPU START", "xmrig.cmd CPU STOP", "xmrig-proxy.cmd GPU START", "xmrig.cmd GPU STOP". 
If you run it without any params (and "ALLOW_MANUAL_SELECT" set to "true") you can manually select what ever you want to run.

If miner ("xmrig.exe" or "xmrig-nvidia.exe" file) already started, it will be automatically closed (killed process).

Don't forget to put exe files to "CPU" and "GPU" folders and change "WALLET", "DIFF", "ID", "EMAIL", "PROGRAM_CPU_PARAMETERS" and "PROGRAM_GPU_PARAMETERS" in a CMD to your personal settings at your choice. Good luck!

No one known bug currently.
