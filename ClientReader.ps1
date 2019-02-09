
$DBServer = "192.168.50.150"
$DBName = "homecontrol"
$DBUser = "dbuser"
$DBPassword = "dbuserpwd123"

Import-Module /home/pi/PiHomeControl/PiHomeControl.psm1 -Force

modprobe btusb
systemctl stop bluetooth
systemctl start bluetooth
$ScriptBlock = { hcitool lescan --duplicates > /home/pi/PiHomeControl/BTScan.results }
Start-Job -name BTScan -ScriptBlock $ScriptBlock
$BluetoothDevices = @{}

do
{
    Start-Sleep -Seconds 10
    Rename-Item /home/pi/PiHomeControl/BTScan.results BTScan.reading
    foreach ($Line in (Get-Content /home/pi/PiHomeControl/BTScan.reading))
    {
        if ($Line.Split(' ')[0] -match '[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]')
        {
            if ($Line.Split(' ')[1] -match 'CC-RT-M-BLE') 
            { 
                if ($BluetoothDevices.Keys -notcontains $Line.Split(' ')[0]) 
                { 
                    $BluetoothDevices.Add($Line.Split(' ')[0],$Line.Split(' ')[1].Trim()) 
                }
                else 
                {
                    $BluetoothDevices.($Line.Split(' ')[0]) = $Line.Split(' ')[1]
                }
                Write-Host "Updating PostreSQL"
                $MACAddress = $Line.Split(' ')[0].Trim()
                $Statement = "INSERT INTO eq3thermostats (eq3macaddress) SELECT '$MACAddress'";
                Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword
    
            }
            else 
            {
                if ($BluetoothDevices.Keys -notcontains $Line.Split(' ')[0]) 
                { 
                    $BluetoothDevices.Add($Line.Split(' ')[0],$Line.Split(' ')[1].Trim()) 
                }    
            }
        }
    }


} until ($Something)

<#foreach ($MACAddress in (Get-EQ3Thermostats)) 
{ 
    $MACAddress
    Get-EQ3Temperature -MACAddress $MACAddress 
}

foreach ($MACAddress in (Get-EQ3Thermostats)) { Set-EQ3Temperature -MACAddress $MACAddress -Temperature 22 }
#>