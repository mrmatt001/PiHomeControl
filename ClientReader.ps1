
$DBServer = "192.168.50.150"
$DBName = "homecontrol"
$DBUser = "dbuser"
$DBPassword = "dbuserpwd123"

Import-Module /home/pi/PiHomeControl/PiHomeControl.psm1 -Force

modprobe btusb
systemctl stop bluetooth
systemctl start bluetooth
$BluetoothDevices = @{}

if (Get-Job -Name BTScan -ErrorAction SilentlyContinue) { Get-Job -Name BTScan | Remove-Job -Force }
do
{
    $ScriptBlock = { hcitool lescan --duplicates > /home/pi/PiHomeControl/BTScan.results }
    Start-Job -name BTScan -ScriptBlock $ScriptBlock
    Start-Sleep -Seconds 60
    if (Test-Path /home/pi/PiHomeControl/BTScan.reading) { Remove-Item /home/pi/PiHomeControl/BTScan.reading }
    if (Test-Path /home/pi/PiHomeControl/BTScan.results) 
    { 
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
        Remove-Item /home/pi/PiHomeControl/BTScan.reading
    }
    if (Get-Job -Name BTScan -ErrorAction SilentlyContinue) { Get-Job -Name BTScan | Remove-Job -Force }
} until ($Something)

<#foreach ($MACAddress in (Get-EQ3Thermostats)) 
{ 
    $MACAddress
    Get-EQ3Temperature -MACAddress $MACAddress 
}

foreach ($MACAddress in (Get-EQ3Thermostats)) { Set-EQ3Temperature -MACAddress $MACAddress -Temperature 22 }
#>