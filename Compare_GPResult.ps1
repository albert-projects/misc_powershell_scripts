
#import CSV file into object
$File_Location = "\\files\PUBLIC\Logs\GPResult"
$after_csv = "$File_Location\GPResult_after.csv"
$before_csv = "$File_Location\GPResult_before.csv"
$compared_csv = "$File_Location\Compared.csv"

# check if exist result log file, rename it
$Time = Get-Date -Format "yyyyMMdd-HHmm"
$Time = $Time.ToString()

if (Test-Path $compared_csv) {

    $New_name = "compared_csv" + $Time + ".csv"
    Rename-Item $compared_csv -NewName $New_name
}

#re-create the log file
Add-Content -Path $compared_csv -Value '"UserID","AppliedGPO","DriveLetter","Printer","OUPath"'


$before = Import-Csv -Path $before_csv
$after = Import-Csv -Path $after_csv

function Compare_Item {

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Item_1,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Item_2

    )

    # compare code
    #for same GPO Naming
    if ($Item_1.Substring(0,3) -eq "Old"){

        $tmp1 = $Item_1.ToString().Substring(4)
        $tmp2 = $Item_2.ToString().Substring(4)
        if($tmp1 -eq $tmp2 ) {
    
            return "True"
        }
    }

    #for U-Set-Library-IESetting
    if ($Item_1 -eq "Old_U-Set-Library-IESettingAndMapDrive"){

        $tmp1 = "U-Set-Library-IESetting"
        $tmp2 = $Item_2.ToString().Substring(4)
        if($tmp1 -eq $tmp2 ) {
    
            return "True"
        }
    }

    #for Old_U-Set-SetRegionAndScreenSaver
    if ($Item_1 -eq "Old_U-Set-SetRegionAndScreenSaver"){

        $tmp1 = "U-Set-AllUser-SetRegionHomeLocationAU"
        $tmp2 = $Item_2.ToString().Substring(4)
        if($tmp1 -eq $tmp2 ) {

            return "True"
        }
    }

    #for New_U-Set-AllUser-SetScreenSaver, backward loopup for after list
    if ($Item_1 -eq "New_U-Set-AllUser-SetScreenSaver"){

        $tmp1 = "U-Set-SetRegionAndScreenSaver"
        $tmp2 = $Item_2.ToString().Substring(4)
        if($tmp1 -eq $tmp2 ) {

            return "True"
        }
    }

    #for drive mapped
    if ($Item_1 -like "[A-Z]:\\*"){

        $tmp1 = $Item_1
        $tmp2 = $Item_2
        if($tmp1 -eq $tmp2 ) {

            return "True"
        }
    }

    #for printer mapped
    if ($Item_1.ToUpper() -like "\\VPSPADPS01\*"){

        $tmp1 = $Item_1.ToUpper()
        $tmp2 = $Item_2.ToUpper()
        if($tmp1 -eq $tmp2 ) {

            return "True"
        }
    }




}

 $obj_BeforeList = $before 
 $obj_BeforeList | Add-Member -NotePropertyName Status1 -NotePropertyValue $null
 $obj_BeforeList | Add-Member -NotePropertyName Status2 -NotePropertyValue $null
 $obj_BeforeList | Add-Member -NotePropertyName Status3 -NotePropertyValue $null
 #$obj_BeforeList | Get-Member -MemberType NoteProperty

 $obj_AfterList = $after 
 $obj_AfterList | Add-Member -NotePropertyName Status1 -NotePropertyValue $null
 $obj_AfterList | Add-Member -NotePropertyName Status2 -NotePropertyValue $null
 $obj_AfterList | Add-Member -NotePropertyName Status3 -NotePropertyValue $null
 #$obj_AfterList | Get-Member -MemberType NoteProperty


Foreach ($before_record in $obj_BeforeList) {

    Write-Host "Comparing "$before_record.UserID

    #count number of object goint to compare
    #$count = $obj_AfterList | Where-Object { $after_record.AppliedGPO -eq "DefaultDomainPolicy" } 
    $total_count = ($obj_AfterList | ?{$($_.AppliedGPO) -ne '' -and ($_.UserID -eq $before_record.UserID ) ;} | Measure-Object).Count
    $total_drive_count = ($obj_AfterList | ?{$($_.DriveLetter) -ne '' -and ($_.UserID -eq $before_record.UserID ) ;} | Measure-Object).Count
    $total_printer_count = ($obj_AfterList | ?{$($_.Printer) -ne '' -and ($_.UserID -eq $before_record.UserID ) ;} | Measure-Object).Count
        
    #Write-Host "Total Drive" $total_drive_count
    $run_count = 0
    $GPOIgnore = ""
    $drive_run_count = 0
    $DriveIgnore = ""
    $printer_run_count = 0
    $PrinterIgnore = ""

    Foreach ($after_record in $obj_AfterList) {    
        
        #Write-Host "Comparing "$before_record.AppliedGPO" to "$after_record.AppliedGPO
        #reset the flag
        #$after_record.Status1 = ""
        if ($before_record.UserID -eq $after_record.UserID){
           
            # compare applied GPO
            #$GrepOut = "N"
            if ( $after_record.AppliedGPO -ne ""){   
              
                if(      $before_record.AppliedGPO -ne "DefaultDomainPolicy" `
                    -and $before_record.AppliedGPO -ne "Old_Map-NetworkDrives" `
                    -and $after_record.AppliedGPO -notlike "U-Map-Drive*" `
                    -and $after_record.AppliedGPO -ne "DefaultDomainPolicy" `
                    -and $before_record.AppliedGPO -ne "" `
                    -and $after_record.AppliedGPO -ne "" `
                    -and $before_record.AppliedGPO -ne "Old_U-PlanningDevelopment-MapDrive" ){
            
                    Write-Host "Comparing "$before_record.AppliedGPO" to "$after_record.AppliedGPO
                    $result = Compare_Item -Item_1 $before_record.AppliedGPO -Item_2 $after_record.AppliedGPO

                    $GPOIgnore = "N"

                    if ($result -eq "True"){
                    
                        $after_record.Status1 = "GPO_Compared"
                        #$Match = "Y"
                        break
                
                    }
    
                }
                $run_count++  
                #Write-Host "GPO count" $run_count
            #}else{

                #$GrepOut = "Y1"
                #Write-Host $before_record.AppliedGPO
                #$diff_record = New-Object System.Object
                #$diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
                #$diff_record | Add-Member -MemberType NoteProperty -Name "AppliedGPO" -Value $before_record.AppliedGPO
                #$diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
                #$diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force

            }

            #compare Network drive
            #$GrepOut = "N"
            if ( $after_record.DriveLetter -ne ""){ 
             
                    if(      $before_record.DriveLetter -ne "" `
                    -and $after_record.DriveLetter -ne ""  ){
                    #if(      $before_record.DriveLetter -ne "" ){

                        Write-Host "Comparing "$before_record.DriveLetter" to "$after_record.DriveLetter
                        $result = Compare_Item -Item_1 $before_record.DriveLetter -Item_2 $after_record.DriveLetter

                        $DriveIgnore = "N"

                        if ($result -eq "True"){
                    
                        $after_record.Status2 = "Drive_Compared"
                        break
                
                        }


                    }
                    $drive_run_count++ 
                    #Write-Host  "drive count" $drive_run_count

            #}else{
            
                #$GrepOut = "Y2"
                #Write-Host $before_record.DriveLetter
                #$diff_record = New-Object System.Object
                #$diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
                #$diff_record | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $before_record.DriveLetter
                #$diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
                #$diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
                
            }


            #compare printer
            #$GrepOut = "N"
            if ( $after_record.Printer -ne ""){ 
             
                    if(      $before_record.Printer -ne "" `
                    -and $after_record.Printer -ne ""  ){
                    #if(      $before_record.Printer -ne "" ){

                        Write-Host "Comparing "$before_record.Printer" to "$after_record.Printer
                        $result = Compare_Item -Item_1 $before_record.Printer -Item_2 $after_record.Printer

                        $PrinterIgnore = "N"

                        if ($result -eq "True"){
                    
                        $after_record.Status3 = "Printer_Compared"
                        break
                
                        }


                    }
                    $printer_run_count++ 
                    #Write-Host  "drive count" $drive_run_count

            #}else{
            
                #$GrepOut = "Y3"
                #Write-Host $before_record.Printer
                #$diff_record = New-Object System.Object
                #$diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
                #$diff_record | Add-Member -MemberType NoteProperty -Name "Printer" -Value $before_record.Printer
                #$diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
                #$diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
                
            }

        }
        
    }

    if($run_count -ge $total_count -and $GPOIgnore -eq "N" ){
        Write-Host "Count $run_count, Total $total_count, "$before_record.AppliedGPO
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "AppliedGPO" -Value $before_record.AppliedGPO
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
    }

    if($drive_run_count -ge $total_drive_count -and $DriveIgnore -eq "N" ){
        Write-Host "Count $drive_run_count, Total $total_drive_count, "$before_record.DriveLetter
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $before_record.DriveLetter
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
    }

    if($printer_run_count -ge $total_printer_count -and $PrinterIgnore -eq "N" ){
        Write-Host "Count $printer_run_count, Total $total_printer_count, "$before_record.Printer
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "Printer" -Value $before_record.Printer
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
    }

    if( $total_count -eq 0  -and $before_record.AppliedGPO -ne ""){
        Write-Host $before_record.AppliedGPO
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "AppliedGPO" -Value $before_record.AppliedGPO
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
    }

    if($total_drive_count -eq 0  -and $before_record.DriveLetter -ne ""){
        Write-Host $before_record.DriveLetter
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $before_record.DriveLetter
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
    }

    if($total_printer_count -eq 0 -and $before_record.Printer -ne "" ){
        Write-Host $before_record.Printer
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $before_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "Printer" -Value $before_record.Printer
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $before_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
    }
    
}

#$obj_AfterList

#backward compare
Foreach ($after_record in $obj_AfterList) {


    Write-Host "Backward comparing "$after_record.UserID
    $total_count = ($obj_BeforeList | ?{$($_.AppliedGPO) -ne '' -and ($_.UserID -eq $after_record.UserID ) ;} | Measure-Object).Count
    $drive_total_count = ($obj_BeforeList | ?{$($_.DriveLetter) -ne '' -and ($_.UserID -eq $after_record.UserID ) ;} | Measure-Object).Count
    $total_printer_count = ($obj_BeforeList | ?{$($_.Printer) -ne '' -and ($_.UserID -eq $after_record.UserID ) ;} | Measure-Object).Count

    #Write-Host Total $count
    $run_count = 0
    $GPOIgnore = ""
    $drive_run_count = 0
    $DriveIgnore = ""
    $printer_run_count = 0
    $PrinterIgnore = ""


    Foreach ($before_record in $obj_BeforeList) {

        if ($before_record.UserID -eq $after_record.UserID){
        
            #for GPO
            if ($after_record.Status1 -ne "GPO_Compared"  -and $after_record.AppliedGPO -ne ""){

                # compare applied GPO     
                #$GrepOut = "N"       
                if ( $before_record.AppliedGPO -ne ""){   
              
                    if(      $before_record.AppliedGPO -ne "DefaultDomainPolicy" `
                        -and $before_record.AppliedGPO -ne "Old_Map-NetworkDrives" `
                        -and $after_record.AppliedGPO -notlike "U-Map-Drive*" `
                        -and $after_record.AppliedGPO -ne "DefaultDomainPolicy" `
                        -and $before_record.AppliedGPO -ne "" `
                        -and $after_record.AppliedGPO -ne "" `
                        -and $before_record.AppliedGPO -ne "Old_U_PlanningDevelopment-MapDrive" ){
            
                        Write-Host "Backward comparing "$after_record.AppliedGPO" to "$before_record.AppliedGPO
                        $result = Compare_Item -Item_1 $after_record.AppliedGPO -Item_2 $before_record.AppliedGPO

                        $GPOIgnore = "N"

                        if ($result -eq "True"){
                    
                            $before_record.Status1 = "GPO_Compared"
                            #$Match = "Y"
                            break
                
                        }
    
                    }
                    $run_count++  
                    #Write-Host $run_count
                #}else{
            
                    #$GrepOut = "Y4"
                    #Write-Host $after_record.AppliedGPO
                    #$diff_record = New-Object System.Object
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "AppliedGPO" -Value $after_record.AppliedGPO
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
                    #$diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
                
                }

            }


            #for Drive Mapping
            if ($after_record.Status2 -ne "Drive_Compared"  -and $after_record.DriveLetter -ne ""){

                # compare applied drive 
                #$GrepOut = "N"           
                if ( $before_record.DriveLetter -ne ""){   
              
                    if(      $before_record.DriveLetter -ne "" `
                        -and $after_record.DriveLetter -ne ""  ){
                    #if( $after_record.DriveLetter -ne ""  ){
            
                        Write-Host "Backward comparing "$after_record.DriveLetter" to "$before_record.DriveLetter
                        $result = Compare_Item -Item_1 $after_record.DriveLetter -Item_2 $before_record.DriveLetter

                        $DriveIgnore = "N"

                        if ($result -eq "True"){
                    
                            $before_record.Status2 = "Drive_Compared"
                            #$Match = "Y"
                            break
                
                        }
    
                    }
                    $drive_run_count++  
                    #Write-Host $run_count
                #}else{
            
                    #$GrepOut = "Y5"
                    #Write-Host $after_record.DriveLetter
                    #$diff_record = New-Object System.Object
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $after_record.DriveLetter
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
                    #$diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force

                
                }

            }

            #for printer Mapping
            if ($after_record.Status3 -ne "Printer_Compared"  -and $after_record.Printer -ne ""){

                # compare applied printer   
                #$GrepOut = "N"         
                if ( $before_record.Printer -ne ""){   
              
                    if(      $before_record.Printer -ne "" `
                        -and $after_record.Printer -ne ""  ){
                    #if( $after_record.Printer -ne ""  ){
            
                        Write-Host "Backward comparing "$after_record.Printer" to "$before_record.Printer
                        $result = Compare_Item -Item_1 $after_record.Printer -Item_2 $before_record.Printer

                        $PrinterIgnore = "N"

                        if ($result -eq "True"){
                    
                            $before_record.Status3 = "Printer_Compared"
                            #$Match = "Y"
                            break
                
                        }
    
                    }
                    $printer_run_count++  
                    #Write-Host $run_count
                #}else{
                
                    #$GrepOut = "Y6"
                    #Write-Host $after_record.Printer
                    #$diff_record = New-Object System.Object
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "Printer" -Value $after_record.Printer
                    #$diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
                    #$diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
                
                
                }

            }

        
        }


    }

    if($run_count -ge $total_count -and $GPOIgnore -eq "N" ){
        Write-Host "Count $run_count, Total $total_count, "$after_record.AppliedGPO
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "AppliedGPO" -Value $after_record.AppliedGPO
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
        
     }


    if($drive_run_count -ge $drive_total_count -and $DriveIgnore -eq "N" ){
        Write-Host "Count $drive_run_count, Total $drive_total_count, "$after_record.DriveLetter
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $after_record.DriveLetter
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force

    
    }


    if($printer_run_count -ge $total_printer_count -and $PrinterIgnore -eq "N" ){
        Write-Host "Count $printer_run_count, Total $total_printer_count, "$after_record.Printer
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "Printer" -Value $after_record.Printer
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force

    
    }


    if($total_count -eq 0 -and $after_record.AppliedGPO -ne "" ){
        Write-Host "Count $run_count, Total $total_count, "$after_record.AppliedGPO
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "AppliedGPO" -Value $after_record.AppliedGPO
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
        
     }


    if($drive_total_count -eq 0 -and $after_record.DriveLetter -ne ""){
        Write-Host "Count $drive_run_count, Total $drive_total_count, "$after_record.DriveLetter
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $after_record.DriveLetter
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force

    
    }


    if($total_printer_count -eq 0 -and $after_record.Printer -ne ""){
        Write-Host "Count $printer_run_count, Total $total_printer_count, "$after_record.Printer
        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "Printer" -Value $after_record.Printer
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force

    
    }


}


<#

    #for GPO
    #if ($after_record.Status1 -ne "GPO_Compared" ){

        #Write-Host "Backward comparing "$after_record.UserID
        #count number of object goint to compare
        #$count = $obj_AfterList | Where-Object { $after_record.AppliedGPO -eq "DefaultDomainPolicy" } 
        #$total_count = ($obj_BeforeList | ?{$($_.AppliedGPO) -ne '' -and ($_.UserID -eq $after_record.UserID ) ;} | Measure-Object).Count
        #$drive_total_count = ($obj_BeforeList | ?{$($_.DriveLetter) -ne '' -and ($_.UserID -eq $after_record.UserID ) ;} | Measure-Object).Count

        
        #Write-Host Total $count
        #$run_count = 0
        #$GPOIgnore = ""
        #$drive_run_count = 0
        #$DriveIgnore = ""

        Foreach ($before_record in $obj_BeforeList) {

         #for GPO
         if ($after_record.Status1 -ne "GPO_Compared" -and $after_record.AppliedGPO -ne "" ){
 
         #reset the flag
         #$before_record.Status1 = ""
         #Write-Host "Comparing "$before_record.AppliedGPO" to "$after_record.AppliedGPO
         if ($before_record.UserID -eq $after_record.UserID){

            # compare applied GPO            
            if ( $before_record.AppliedGPO -ne ""){   
              
                if(      $before_record.AppliedGPO -ne "DefaultDomainPolicy" `
                    -and $before_record.AppliedGPO -ne "Old_Map-NetworkDrives" `
                    -and $after_record.AppliedGPO -notlike "U-Map-Drive*" `
                    -and $after_record.AppliedGPO -ne "DefaultDomainPolicy" `
                    -and $before_record.AppliedGPO -ne "" `
                    -and $after_record.AppliedGPO -ne "" `
                    -and $before_record.AppliedGPO -ne "Old_U_PlanningDevelopment-MapDrive" ){
            
                    Write-Host "Backward comparing "$after_record.AppliedGPO" to "$before_record.AppliedGPO
                    $result = Compare_Item -Item_1 $after_record.AppliedGPO -Item_2 $before_record.AppliedGPO

                    $GPOIgnore = "N"

                    if ($result -eq "True"){
                    
                        $before_record.Status1 = "GPO_Compared"
                        #$Match = "Y"
                        break
                
                    }
    
                }
                $run_count++  
                #Write-Host $run_count
            }

        }       
                    
        }
        
        if($run_count -eq $total_count -and $GPOIgnore -eq "N" ){

        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "AppliedGPO" -Value $after_record.AppliedGPO
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
        
        }


    # for Drive Mapped
        if ($after_record.Status2 -ne "Drive_Compared" -and $after_record.DriveLetter -ne ""){

        Write-Host "Backward comparing drive mapping "$after_record.UserID
        #count number of object goint to compare
        #$count = $obj_AfterList | Where-Object { $after_record.AppliedGPO -eq "DefaultDomainPolicy" } 
        #$total_count = ($obj_BeforeList | ?{$($_.DriveLetter) -ne '' -and ($_.UserID -eq $after_record.UserID ) ;} | Measure-Object).Count

        
        #Write-Host Total $count
        #$run_count = 0
        #$DriveIgnore = ""    
 
         #reset the flag
         #$before_record.Status1 = ""
         #Write-Host "Comparing "$before_record.AppliedGPO" to "$after_record.AppliedGPO
         if ($before_record.UserID -eq $after_record.UserID){

            # compare applied Drive            
            if ( $before_record.DriveLetter -ne ""){   
              
                if(      $before_record.DriveLetter -ne "" `
                    -and $after_record.DriveLetter -ne ""  ){
            
                    Write-Host "Backward comparing "$after_record.DriveLetter" to "$before_record.DriveLetter
                    $result = Compare_Item -Item_1 $after_record.DriveLetter -Item_2 $before_record.DriveLetter

                    $DriveIgnore = "N"

                    if ($result -eq "True"){
                    
                        $before_record.Status2 = "Drive_Compared"
                        #$Match = "Y"
                        break
                
                    }
    
                }
                $drive_run_count++  
                #Write-Host $run_count
            }

        }       
                    
        
        }
        }
        if($drive_run_count -eq $drive_total_count -and $DriveIgnore -eq "N" ){

        $diff_record = New-Object System.Object
        $diff_record | Add-Member -MemberType NoteProperty -Name "UserID" -Value $after_record.UserID
        $diff_record | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $after_record.DriveLetter
        $diff_record | Add-Member -MemberType NoteProperty -Name "OUPath" -Value $after_record.OUPath
        $diff_record | Export-Csv -Path $compared_csv -Append -NoTypeInformation -Force
    

    
    }



}


#$obj_AfterList
#>