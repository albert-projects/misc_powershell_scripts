    
$currentuser = gwmi -Class win32_computersystem | select -ExpandProperty username
$process = get-process logonui -ea silentlycontinue

if($currentuser -and $process){
    exit 0
}else{
    
    $NoCount = 0
    $msg=$args[0]


    do{
        Add-Type -AssemblyName System.Windows.Forms

        $sh = New-Object -ComObject "Wscript.Shell"
        $UserResponse = $sh.Popup($msg,300,"Status",1+4096)
        #Start-Sleep -Seconds 5
        write-host $UserResponse 
        #$UserResponse = [System.Windows.Forms.MessageBox]::Show($this, $msg , "Status" , 4)
        #if($startDate.AddSeconds(5) -gt (Get-Date)) { exit 1}
        if ($UserResponse -eq 1 ) 
        {
            #Yes activity
            Write-Host "YES"
        } 
        if ($UserResponse -eq 2 ) 
        { 
            #No activity
            Write-Host "NO"
            $NoCount++
            Start-Sleep -Seconds 60
        }
        if ($UserResponse -eq -1 ) 
        { 
            #No activity
            Write-Host "NO Answer"
            {exit 0}
        } 
        if($NoCount -gt 2) { exit 1}      

    } while ($UserResponse -eq 2)

}