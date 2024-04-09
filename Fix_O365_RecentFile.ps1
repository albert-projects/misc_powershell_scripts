
$SW = "PowerPoint","Word","Excel"

#$dest_key = Get-ChildItem -Path "HKCU:\Software\Microsoft\Office\16.0\Excel\User MRU" | where {$_.Name -match 'ADAL_'}
#if ( $dest_key -eq $null)
#{
#    Write-Host "Null"
#}

foreach($app in $SW)
{
    $source_key = Get-ChildItem -Path "HKCU:\Software\Microsoft\Office\16.0\$app\User MRU" | where {$_.Name -match 'AD_'}
    $dest_key = Get-ChildItem -Path "HKCU:\Software\Microsoft\Office\16.0\$app\User MRU" | where {$_.Name -match 'ADAL_'}
    if ( $dest_key -eq $null)
    {
        switch ($app)
        {
           "PowerPoint" { $exe = "POWERPNT.EXE"}
           "Word" { $exe = "WINWORD.EXE"}
           "Excel" {$exe = "EXCEL.EXE"}       
        }
        #run the application, and create the register key
        & "C:\Program Files\Microsoft Office\root\Office16\$exe"
        do{
          Start-Sleep -Seconds 2
          $dest_key = Get-ChildItem -Path "HKCU:\Software\Microsoft\Office\16.0\$app\User MRU" | where {$_.Name -match 'ADAL_'}
          #$dest_key

        } while ($dest_key -eq $null)

        #kill the application
        & taskkill /IM $exe /F

        #Write-Host "Null"
    }
    #copy recent file history
    & "C:\Windows\System32\reg.exe" copy $source_key $dest_key /s /f

} 
 