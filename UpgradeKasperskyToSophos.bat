@echo off

rem Remove Kaspersky Endpoint Security for Windows 11.0.0.6499
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{E7012AFE-DB97-4B8B-9513-E98C0C3AACE3} >NUL 2>NUL || MsiExec.exe /qn /norestart /X {E7012AFE-DB97-4B8B-9513-E98C0C3AACE3}

rem Remove Kaspersky Security 10 for Windows Server
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1F39FF72-CA21-42B6-8113-1621C04814DA} >NUL 2>NUL || MsiExec.exe /qn /norestart /X {1F39FF72-CA21-42B6-8113-1621C04814DA}

rem Remove Kaspersky Security Center 10 Network Agent 10.3.407
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF4CF24-88AB-45E1-A6E6-40C8278A70C5} >NUL 2>NUL || MsiExec.exe /qn /norestart /X {BCF4CF24-88AB-45E1-A6E6-40C8278A70C5} 

rem Remove Kaspersky Security 10.1.2 for Windows Server 10.1.2.996
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{93EDBC7E-D73F-4401-84A5-79E8CBB8B843} >NUL 2>NUL || MsiExec.exe /qn /norestart /X {93EDBC7E-D73F-4401-84A5-79E8CBB8B843}


rem Install Sophos
\\files\kits$\_Deployment\Packages\SophosSetup.exe --quiet

pause