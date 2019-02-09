
$DBServer = "192.168.50.150"
$DBName = "homecontrol"
$DBUser = "dbuser"
$DBPassword = "dbuserpwd123"

Import-Module /home/pi/PiHomeControl/PiHomeControl.psm1 -Force

$BluetoothDevices = @{}

if (Get-Job -Name BTScan -ErrorAction SilentlyContinue) { Get-Job -Name BTScan | Remove-Job -Force }
do
{
    modprobe btusb
    systemctl stop bluetooth
    systemctl start bluetooth
    $ScriptBlock = { hcitool lescan --duplicates > /home/pi/PiHomeControl/BTScan.results }
    Start-Job -name BTScan -ScriptBlock $ScriptBlock | Out-Null
    
    Start-Sleep -Seconds 30
    
    if (Test-Path /home/pi/PiHomeControl/BTScan.reading) { Remove-Item /home/pi/PiHomeControl/BTScan.reading }
    if (Test-Path /home/pi/PiHomeControl/BTScan.results) 
    { 
        if ((get-item ./BTScan.results).Length -gt 0) 
        {
            Write-Host "stuff to do"
            Rename-Item /home/pi/PiHomeControl/BTScan.results BTScan.reading
            foreach ($Line in (Get-Content /home/pi/PiHomeControl/BTScan.reading))
            {
                $Line
                if ($Line.Split(' ')[0] -match '[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]')
                {
                    Write-Host ("MAC Address " + $Line.Split(' ')[0]) -ForegroundColor Green
                    if ($Line.Split(' ')[1] -match 'CC-RT-M-BLE') 
                    { 
                        if ($BluetoothDevices.Keys -notcontains $Line.Split(' ')[0]) 
                        { 
                            $BluetoothDevices.Add($Line.Split(' ')[0],$Line.Split(' ')[1].Trim()) 
                            $MACAddress = $Line.Split(' ')[0].Trim()
                            Write-Host "Updating PostreSQL with $MACAddress"
                            $Statement = "INSERT INTO eq3thermostats (eq3macaddress) SELECT '$MACAddress'";
                            Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword
                        }
                        else 
                        {
                            $BluetoothDevices.($Line.Split(' ')[0]) = $Line.Split(' ')[1]
                        }
                        
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