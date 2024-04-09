
Invoke-Command -ComputerName C8D3FFB99AEFP -ScriptBlock{

    $productNames = @("*nap*")
    $UninstallKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
                        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
                        )
    $results = foreach ($key in (Get-ChildItem $UninstallKeys) ) {

        foreach ($product in $productNames) {
            if ($key.GetValue("DisplayName") -like "$product") {
                [pscustomobject]@{
                    KeyName = $key.Name.split('\')[-1];
                    DisplayName = $key.GetValue("DisplayName");
                    UninstallString = $key.GetValue("UninstallString");
                    Publisher = $key.GetValue("Publisher");
                }
            }
        }
    }

    $results 

}

<#
Invoke-Command -ComputerName 705A0F30411FP -ScriptBlock{

  & "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\HDBox\Uninstaller.exe" --uninstall=1 --sapCode=CPTL --productVersion=11.1.5 --productPlatform=win32 --productAdobeCode={CPTL-11.1.5-32-ADBEADBEADBEADBEADBEA} --isNonCCProduct=true --productName="Adobe Presenter" --mode=0

}
#>