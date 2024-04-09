# Deploy this via PDQ Deploy or run once as admin

# Delete all Network Printers
#Get-WmiObject -Class Win32_Printer | where{$_.Network -eq 'true'} | ForEach-Object {$_.Delete()}

# Add Driver to the Store
pnputil.exe /a "\\files\kits$\Drivers\Canon\GPlus_PS3_Driver_V250_W64_00\Driver\CNS30MA64.INF"
#pnputil.exe /a "\\files\kits$\Drivers\Canon\GPCL6_V4_PrinterDriver_V21_00\Driver\cnnv4_cp6_fgeneric.inf"

# Install the Driver
# ... example for different Sharp Printers and driver from above
#Add-PrinterDriver -Name "Canon Generic Plus PS3" -InfPath "C:\Windows\System32\DriverStore\FileRepository\cns30ma64.inf_amd64_5f13b4526a6bb97d\CNS30MA64.INF"
#Add-PrinterDriver -Name "Canon Generic PCL6 V4" -InfPath "C:\Windows\System32\DriverStore\FileRepository\cnnv4_cp6_fgeneric.inf_amd64_047885010d48725b\cnnv4_cp6_fgeneric.inf"
#Add-PrinterPort -Name "NUL:" -PrinterHostAddress "MF746C-DEPOT-WORKSHOP"
#Add-Printer -DriverName "Canon Generic Plus PS3" -Name "\\VPSPADPS01\MF746C-DEPOT-WORKSHOP" -PortName "NUL:"

Add-PrinterDriver -Name "Canon Generic Plus PS3"
#Add-PrinterDriver -Name "Canon Generic PCL6 V4"
