
$teamslink = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Teams.exe.lnk"

if (Test-Path $teamslink -PathType leaf)
{
    Remove-Item -Path $teamslink -Force
    Write-Host "removed"    
}