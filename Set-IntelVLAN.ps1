# 13/1/2022 by Albert
# setup vlan for Intel I219-LM network card 
# this script will alias virtual NIC for each vlan channel
#
# you need to Install Drivers and Intel(R) PROSet first \\files\kits$\Drivers\Intel\Wired_PROSet_26.8_x64\Wired_PROSet_26.8_x64.exe
# make sure you have "Intel(R) PROSet Adapter Configuration Utility" 
# and powershell module "C:\Program Files\Intel\Wired Networking\IntelNetCmdlets" after install the driver
# 
# this script need running by administrator
# the port connected to switch need to config as trunk port
#
# reference: https://www.intel.com/content/www/us/en/support/articles/000056184/ethernet-products/gigabit-ethernet-controllers-up-to-2-5gbe.html
#

Import-Module -Name 'C:\Program Files\Intel\Wired Networking\IntelNetCmdlets\IntelNetCmdlets'

function Simple-Menu {
    Param(
        [Parameter(Position=0, Mandatory=$True)]
        [string[]]$MenuItems,
        [string] $Title
    )

    $header = $null
    if (![string]::IsNullOrWhiteSpace($Title)) {
        $len = [math]::Max(($MenuItems | Measure-Object -Maximum -Property Length).Maximum, $Title.Length)
        $header = '{0}{1}{2}' -f $Title, [Environment]::NewLine, ('-' * $len)
    }

    # possible choices: didits 1 to 9, characters A to Z
    $choices = (49..57) + (65..90) | ForEach-Object { [char]$_ }
    $i = 0
    $items = ($MenuItems | ForEach-Object { '[{0}]  {1}' -f $choices[$i++], $_ }) -join [Environment]::NewLine

    # display the menu and return the chosen option
    while ($true) {
        #cls
        if ($header) { Write-Host $header -ForegroundColor Yellow }
        Write-Host $items
        Write-Host
        
        $answer = (Read-Host -Prompt 'Please make your choice').ToUpper()
        $index  = $choices.IndexOf($answer[0])
        Write-Host
        if ($index -ge 0 -and $index -lt $MenuItems.Count) {
            return $MenuItems[$index]
        }
        else {
            Write-Warning "Invalid choice.. Please try again."
            #Start-Sleep -Seconds 2
        }
    }
}

function Start-Menu {

    $menu = 'Get-IntelNetAdapter', 'Get-IntelNetVLAN', 'Add-IntelNetVLAN', 'Remove-IntelNetVLAN', 'Quit'
    $Selected = Simple-Menu -MenuItems $menu -Title "What would you like to do?"
    return $Selected 
}

function AddVlan-Menu {

    $objNIC=Get-IntelNetAdapter
    $NIC = $objNIC.Name

    # get selected NIC
    $menu = $NIC
    $Selected = Simple-Menu -MenuItems $menu -Title "Which NIC do you want to apply?"
    Write-Host
    $SelectedNIC = $Selected 

    Write-Host "Selected $Selected" -ForegroundColor Green
    Write-Host "You need to have a untagged VLAN (VLAN ID = 0) to make the default VLAN working" -ForegroundColor Yellow
    Write-Host "You need to create an tagged VLAN before a untagged VLAN." -ForegroundColor Yellow
    Write-Host

    # get user input VLAN ID
    $ErrorActionPreference = 'Stop'
    Write-Host
    $FromObj = "Please input VLAN ID"

    $scriptBlock = {
        try
        {
            $FromInput = [int](Read-Host $FromObj)

            if ($FromInput -lt 0) {
                Write-Host "VLAN ID must be between 0 to 4096."
                & $scriptBlock
            }
            elseif ($FromInput -gt 4096) {
                Write-Host "VLAN ID must be between 0 to 4096."
                & $scriptBlock
            }
            else {
                $FromInput
            }
        }
        catch
        {
            Write-Host "VLAN ID must be between 0 to 4096."
            & $scriptBlock
        }
    }

    $VlanID = & $scriptBlock

    #run add vlan 
    try
    {
        $action = Add-IntelNetVLAN -ParentName $SelectedNIC -VLANID $VlanID
        if ($action){
        
            $SelectedVLAN = $action.Caption

            Write-Host "Virtual NIC $SelectedVLAN has been added"
            Write-Host
        }
    }
    catch
    {
        #Write-Host "VLAN error, it might have duplicate VLAN ID exist, please try again."
        Write-Host "Create VLAN error! please try again." -ForegroundColor Red
        Write-Host $Error[0].Exception -ForegroundColor Red
        Write-Host
        Write-Host
    }


}

function RemoveVlan-Menu {

    $objVLAN=Get-IntelNetVLAN
    $Vlan = $objVLAN.Caption

    #Write-Host $Vlan
    Write-Host

    # get selected VLAN
    $menu = $Vlan
    $Selected = Simple-Menu -MenuItems $menu -Title "Which NIC do you want to apply?"
    Write-Host
    $SelectedVLAN = $Selected 
    $SelectedVLAN

    #$separator = " - VLAN :"
    #$ind = $SelectedVLAN.IndexOf($separator)
    #$NIC = $SelectedVLAN.Substring(0,$ind)
    #Write-Host $NIC

    $SelectedNIC = $objVLAN | Where {$_.Caption -eq "$SelectedVLAN"} | Select Caption, VLANID, ParentName
    #Write-Host $SelectedNIC | FT

    try
    {
        Remove-IntelNetVLAN -ParentName $SelectedNIC.ParentName -VLANID $SelectedNIC.VLANID
        
        #$SelectedVLAN = $SelectedNIC.Caption
        Write-Host "Virtual NIC $SelectedVLAN has been removed."
        Write-Host
        Write-Host

    }
    catch
    {
        Write-Host "VLAN error, please list the VLAN and try again."
        Write-Host
        Write-Host
    }
}


do{
    $Choose = Start-Menu

    switch ($Choose) {

        'Get-IntelNetAdapter' {
            $NIC = Get-IntelNetAdapter
            #Write-Host "`r`n $NIC `r`n"  
            $NIC | FT
            Write-Host
          
        }
        'Get-IntelNetVLAN' {
            $VLAN = Get-IntelNetVLAN
            #Write-Host "`r`n $NIC `r`n"  

            if ($VLAN -ne $null){
                $VLAN | FT
            }else{
                Write-Host "No vlan setting, using default network setting."
                Write-Host
            }
        }
        'Add-IntelNetVLAN' {
            AddVlan-Menu       
        }
        'Remove-IntelNetVLAN' {
            RemoveVlan-Menu     
        }


    }
} until ($Choose -eq 'Quit')