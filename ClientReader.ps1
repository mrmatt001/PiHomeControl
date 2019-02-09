
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
                        #Write-Host ("EQ3 " + $Line) -ForegroundColor Green
                        #$Statement = "INSERT INTO eq3thermostats (eq3macaddress) SELECT '$MACAddress'";
                        #Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword
                        if ($BluetoothDevices.Keys -notcontains $MACAddress) 
                        { 
                            $BluetoothDevices.Add("$MACAddress","$Description") 
                            #Write-Host "Updating PostreSQL with $MACAddress"
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
            $RunningJobs = @()
            $JobsStartTime = (Get-Date)
            $BluetoothDevices.Keys | % { 
                if ($BluetoothDevices.Item($_) -eq 'CC-RT-M-BLE') 
                { 
                    #key = $_ , value = " + $BluetoothDevices.Item($_) 
                    $Statement = "INSERT INTO eq3thermostats (eq3macaddress) SELECT '$_'";
                    Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword | Out-Null
                    
                    get-job -Name $_ | Remove-Job -Force
                    Write-Host "Triggering job: $_"
                    $RunningJobs += $_
                    $scriptBlock = [scriptblock]::Create("gatttool -b " + $MACAddress + ' --char-write-req -a "0x0411" -n "03" --listen')
                    $Job = (Start-Job -Name $_ -ScriptBlock $scriptBlock -ArgumentList $MACAddress)
                } 
            }

            do
            {
                $CompletedJobs = 0
                foreach ($Job in $RunningJobs)
                {
                    $JobOutput = Get-Job -Name $Job -ErrorAction SilentlyContinue | Receive-Job -Keep
                    if ($JobOutput -match 'Characteristic') { $CompletedJobs++ }
                    Write-Host "Completed $CompletedJobs of " $RunningJobs).Count
                }
            } until (((((Get-Date).AddSeconds(-30) -gt $JobStartTime))) -or ($CompletedJobs -eq ($RunningJobs).Count))

            foreach ($Job in $RunningJobs)
            {
                $TempOutput = Get-Job -Name $Job | Receive-Job
                $null = Get-Job -Name $Job | Remove-Job -Force
                foreach ($Line in $TempOutput)
                {
                    if ($Line -match 'Notification handle\s+\=\s+\dx\d+\svalue:\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s(?<Temp>[a-zA-Z0-9]+)') 
                    { 
                        [string]$Temperature = ([Convert]::ToInt64(($Matches.Temp),16)/2)
                        #[string]$Temperature = (Get-EQ3Temperature -MACAddress $_)
                        $Temp = (($Temperature -as [decimal]) * 2) -as [int32]
                        $Statement = "UPDATE eq3thermostats SET currenttemperature='$Temp' WHERE eq3macaddress='$Job'";
                        Write-Host $Statement -ForegroundColor Green
                        Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword
                
                    }
                }
            }
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