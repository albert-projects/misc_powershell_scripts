#$computers = "D05833-4MDY933"
$NumSlots = 0

#foreach ($computer in $computers){
    write-host ""
    
    #$colSlots = Get-WmiObject -Class "win32_PhysicalMemoryArray" -ComputerName $computer -namespace "root\CIMV2"
    $colSlots = Get-WmiObject -Class "win32_PhysicalMemoryArray" -namespace "root\CIMV2"
    
    $colSlots | ForEach {
        “Total Number of Memory Slots: ” + $_.MemoryDevices
        $NumSlots = $_.MemoryDevices
        }

    write-host ""

    $SlotsFilled = 0
    $TotMemPopulated = 0
    #$colRAM = Get-WmiObject -Class "win32_PhysicalMemory" -ComputerName $computer -namespace "root\CIMV2" 
    $colRAM = Get-WmiObject -Class "win32_PhysicalMemory" -namespace "root\CIMV2" 
    

    $colRAM | ForEach {
        “Memory Installed: ” + $_.DeviceLocator
        “Memory Size: ” + ($_.Capacity / 1GB) + ” GB”       
        $SlotsFilled = $SlotsFilled + 1
        $TotMemPopulated = $TotMemPopulated + ($_.Capacity / 1GB)
    #   if ($_.Capacity = 0)
    #   {write-host "found free slot"}

        }

    write-host ""
    write-host "=== Summary Memory Slot Info for computer:" $Computer "==="
    write-host ""

    If (($NumSlots - $SlotsFilled) -eq 0){
       write-host "ALL Slots Filled, NO EMPTY SLOTS AVAILABLE!"
       }
    write-host ($NumSlots - $SlotsFilled) " of " $NumSlots " slots Open/Available (Unpopulated)"
    write-host ($SlotsFilled) " of " $NumSlots " slots Used/Filled (Populated)."  
    write-host ""
    write-host "Total Memory Populated = " $TotMemPopulated "GB"
#}