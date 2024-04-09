#Import the module, create a data source and a table
#Import-Module PSSQLite

$ComputerTarget=$args[0]

#$Database = "C:\temp\Database.db"
$Database = "C:\ProgramData\Admin Arsenal\PDQ Inventory\Database.db"
$Query = "select Computers.Name as CN, Applications.Name as AN, Applications.Version as AV, Applications.InstallDate as AI, Computers.SuccessfulScanDate as CS
          from computers, Applications
          where computers.ComputerId = Applications.ComputerId
          and Computers.Name like '%" + $ComputerTarget + "%'
          order by Applications.Name"

#SQLite will create Names.SQLite for us
$result = Invoke-SqliteQuery -Query $Query -DataSource $Database

#$result = "test"

class InstalledApps
{
       # Properties
       [string] $ComputersName
       [string] $ApplicationsName
       [string] $ApplicationsVersion
       [string] $ApplicationsInstallDate
       [string] $ComputersSuccessfulScanDate


       #[void]SetApps([string]$ComputersName, [string]$ApplicationsName,[string]$ApplicationsVersion,[string]$ApplicationsInstallDate,[string]$ComputersSuccessfulScanDate) {
       #$this.ComputersName = $ComputersName
       #$this.ApplicationsName = $ApplicationsName
       #$this.ApplicationsVersion = $ApplicationsVersion
       #$this.ApplicationsInstallDate = $ApplicationsInstallDate
       #$this.ComputersSuccessfulScanDate = $ComputersSuccessfulScanDate
       #}

}

#New-Object -TypeName InstalledApps


#$obj = New-Object InstalledApps
$obj = @()
#$obj 
$count1 = 0
#$temp = [InstalledApps]::new()


foreach ($row in $result){

    $obj += New-Object InstalledApps -Property @{ 
        "ComputersName" = $row.CN
        "ApplicationsName" = $row.AN
        "ApplicationsVersion" = $row.AV
        "ApplicationsInstallDate" =  $row.AI
        "ComputersSuccessfulScanDate" =  $row.CS     
    }
    #$temp = [InstalledApps]::new()
    #$temp.SetApps($row.CN, $row.AN, $row.AV, $row.AI, $row.CS)
    #$obj | Add-Member 
    $count1++
    #New-Object -TypeName InstalledApps
    #$temp = [InstalledApps]::new()
    #$temp.ComputersName = $row.CN
    #$temp.ApplicationsName = $row.AN
    #$temp.ApplicationsVersion = $row.AV
    #$temp.ApplicationsInstallDate = $row.AI
    #$temp.ComputersSuccessfulScanDate = $row.CS

    #$temp = New-Object -TypeName InstalledApps
    #$temp = @()
    #$temp | add-member -MemberType NoteProperty -Name "ComputersName" -Value $row.CN
    #$temp | add-member -MemberType NoteProperty -Name "ApplicationsName" -Value $row.AN
    #$temp | add-member -MemberType NoteProperty -Name "ApplicationsVersion" -Value $row.AV
    #$temp | add-member -MemberType NoteProperty -Name "ApplicationsInstallDate" -Value $row.AI
    #$temp | add-member -MemberType NoteProperty -Name "ComputersSuccessfulScanDate" -Value $row.CS
    
    #$obj += $temp
    #$obj += New-Object -TypeName psobject -Property @{ ComputersName=$row.CN; ApplicationsName=$row.AN; ApplicationsVersion=$row.AV; ApplicationsInstallDate=$row.AI; ComputersSuccessfulScanDate=$row.CS }
    #$obj += New-Object -TypeName psobject -Property @{ ComputersName="1"; ApplicationsName="2"; ApplicationsVersion="3"; ApplicationsInstallDate=$row.AI; ComputersSuccessfulScanDate=$row.CS }
}

#$count
#$obj
return $obj