
$Name = $env:COMPUTERNAME
$file = "\\vwspmsdt01\MDT_Logs\HaveAuthnorn3.txt"



if (!(Test-Connection -ComputerName $Name -count 1 -quiet)) {
    Write-Error -Message "Unable to contact $Name. Please verify its network connectivity and try again." -Category ObjectNotFound -TargetObject $Computer
    Break
}

    $c = Get-Childitem -Path "C:\Program Files\Microsoft Office" -Include *authnorm.dot* -File -Recurse -ErrorAction SilentlyContinue |  % { $_.FullName }

    foreach($item in $c){
        #Write-Host $item.Name
        Remove-Item -Path $item -Force -Verbose
        $result = Test-Path -path $item
        $env:computername + "," + $item + "," + $result  | Out-File -FilePath $file -Append
    }

    $c = Get-Childitem -Path "C:\Program Files (x86)\Microsoft Office" -Include *authnorm.dot* -File -Recurse -ErrorAction SilentlyContinue |  % { $_.FullName }

    foreach($item in $c){
        #Write-Host $item.Name
        Remove-Item -Path $item -Force -Verbose
        $result = Test-Path -path $item
        $env:computername + "," + $item + "," + $result  | Out-File -FilePath $file -Append
    }


