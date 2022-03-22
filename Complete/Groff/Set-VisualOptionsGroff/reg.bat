@echo Off
Echo Windows Explorer Tweaks: Hidden Files,Expand to Current
Echo Change Visual Effects Settings for Best Performance and best looking
:: Change your Visual Effects Settings: https://www.tenforums.com/tutorials/6377-change-visual-effects-settings-windows-10-a.html
:: 0 = Let Windows choose what’s best for my computer
:: 1 = Adjust for best appearance
:: 2 = Adjust for best performance
:: 3 = Custom ;This disables the following 8 settings:Animate controls and elements inside windows;Fade or slide menus into view;Fade or slide ToolTips into view;Fade out menu items after clicking;Show shadows under mouse pointer;Show shadows under windows;Slide open combo boxes;Smooth-scroll list boxes
%SystemRoot%\System32\reg.exe ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f
%SystemRoot%\System32\reg.exe ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f
%SystemRoot%\System32\reg.exe ADD "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "90 32 07 80 10 00 00 00" /f
:: Animate windows when minimizing and maximizing
%SystemRoot%\System32\reg.exe ADD "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /d 0 /f
:: Animations in the taskbar
%SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f
:: Enable Peek
%SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f
:: Save taskbar thumbnail previews
%SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\DWM" /v "AlwaysHibernateThumbnails" /t REG_DWORD /d 0 /f
:: Show translucent selection rectangle
%SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 0 /f
:: Show thumbnails instead of icons
%SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 1 /f
:: Show window contents while dragging
%SystemRoot%\System32\reg.exe ADD "HKCU\Control Panel\Desktop" /v "DragFullWindows" /d 0 /f
:: Smooth edges of screen fonts
%SystemRoot%\System32\reg.exe ADD "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_DWORD /d 2 /f
:: Use drop shadows for icon labels on the desktop
%SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d 1 /f