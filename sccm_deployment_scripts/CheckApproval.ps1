$csv = Import-Csv wds-import.csv;

Foreach ( $line in $csv ) {

    WDSUtil /Add-Device `"/Device:$($line.Hostname)`" /ID:$($line.GUID)

    }