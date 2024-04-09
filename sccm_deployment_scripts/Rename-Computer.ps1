

$name=$args[0]

function Rename-Computer
{
    param ( [Parameter(Mandatory=$true)][string]$name )

    process
    {
        try
        {
            $computer = Get-WmiObject -Class Win32_ComputerSystem
            $result = $computer.Rename($name)

            switch($result.ReturnValue)
            {       
                0 { Write-Host "Success" }
                5 
                {
                    Write-Error "You need administrative rights to execute this cmdlet" 
                    exit
                }
                default 
                {
                    Write-Host "Error - return value of " $result.ReturnValue
                    exit
                }
            }
        }
        catch
        {
            Write-Host "Exception occurred in Rename-Computer " $Error
        }
    }
}

Rename-Computer -name $name