' Nudge watchdog launcher - runs the always-on script completely detached:
' no console window, not tied to any console, immune to console-close kills.
' Used by the Windows Startup folder and Task Scheduler tasks.
CreateObject("Wscript.Shell").Run """" & WScript.Arguments(0) & """", 0, False
