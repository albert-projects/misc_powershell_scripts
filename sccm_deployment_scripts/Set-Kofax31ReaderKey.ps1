$key = 'HKLM:\SOFTWARE\WOW6432Node\Nuance\PDF\GDoc'
New-Item -Path $key -Force
New-ItemProperty -Path $key -Name ReadOnlyMode -Value 1 -PropertyType DWORD -Force 