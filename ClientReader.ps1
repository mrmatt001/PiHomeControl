
$DBServer = "192.168.50.150"
$DBName = "homecontrol"
$DBUser = "dbuser"
$DBPassword = "dbuserpwd123"

Import-Module /home/pi/PiHomeControl/PiHomeControl.psm1 -Force
$ComputerName = (hostname)
$Statement = "INSERT INTO pidevices (pihostname, ostype) SELECT '$ComputerName', 'linuxps'";
Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword | Out-Null

$BluetoothDevices = @{}

if (Get-Job -Name BTScan -ErrorAction SilentlyContinue) { Get-Job -Name BTScan | Remove-Job -Force }
do
{
    modprobe btusb
    systemctl stop bluetooth
    systemctl start bluetooth
    $ScriptBlock = { hcitool lescan --duplicates > /home/pi/PiHomeControl/BTScan.results }
    Start-Job -name BTScan -ScriptBlock $ScriptBlock | Out-Null
    
    Start-Sleep -Seconds 15
    
    if (Test-Path /home/pi/PiHomeControl/BTScan.reading) { Remove-Item /home/pi/PiHomeControl/BTScan.reading }
    if (Test-Path /home/pi/PiHomeControl/BTScan.results) 
    { 
        if ((get-item /home/pi/PiHomeControl/BTScan.results).Length -gt 0) 
        {
            Rename-Item /home/pi/PiHomeControl/BTScan.results /home/pi/PiHomeControl/BTScan.reading
            foreach ($Line in (Get-Content /home/pi/PiHomeControl/BTScan.reading))
            {
                $MACAddress = $Line.Split(' ')[0]
                $Description = $Line.Split(' ')[1]
                if ($MACAddress -match '[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]')
                {
                    if ($Description -match 'CC-RT-M-BLE') 
                    { 
                        if ($BluetoothDevices.Keys -notcontains $MACAddress) 
                        { 
                            $BluetoothDevices.Add("$MACAddress","$Description") 
                        }
                        else 
                        {
                            $BluetoothDevices.($MACAddress) = $Description
                        }
                        
                    }
                    else 
                    {
                        if ($BluetoothDevices.Keys -notcontains $MACAddress) 
                        { 
                            $BluetoothDevices.Add($MACAddress,$Description) 
                        }    
                    }
                }
            }
            Remove-Item /home/pi/PiHomeControl/BTScan.reading
            $BluetoothDevices.Keys | ForEach-Object { 
                if ($BluetoothDevices.Item($_) -eq 'CC-RT-M-BLE') 
                { 
                    $Statement = "INSERT INTO eq3thermostats (eq3macaddress) SELECT '$_'";
                    Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword | Out-Null
                    Write-Host "Getting temp: $_"
                    [string]$Temperature = (Get-EQ3Temperature -MACAddress $_)
                    $Temp = (($Temperature -as [decimal]) * 2) -as [int32]
                    if ($Temp -ne 0)
                    {
                        $Statement = "UPDATE eq3thermostats SET currenttemperature='$Temp' WHERE eq3macaddress='$_'";
                        Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword | Out-Null
                    
                        $ScanDate = (Get-Date)
                        $insert = "INSERT INTO pitoeq3(pihostname, eq3macaddress, lastdetected) VALUES ('$ComputerName','$_','$ScanDate')"
                        $update = "UPDATE pitoeq3 SET lastdetected='$ScanDate' WHERE pihostname='$ComputerName' AND eq3macaddress='$_'";
                        if (!(Write-ToPostgreSQL -Statement $insert -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword))
                        {
                            Write-ToPostgreSQL -Statement $update -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword
                        }
                    }
                }
            }
        }
    }
    if (Get-Job -Name BTScan -ErrorAction SilentlyContinue) { Get-Job -Name BTScan | Remove-Job -Force }
} until ($Something)
