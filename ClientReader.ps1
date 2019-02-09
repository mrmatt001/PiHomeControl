Import-Module /home/pi/PiHomeControl/PiHomeControl.psm1 -Force

modprobe btusb
#systemctl stop bluetooth
#systemctl start bluetooth
#hciconfig hci0 down
#hciconfig hci0 up
#$ScanOnJob = Start-Job -ScriptBlock {
    "scan on" | bluetoothctl #}
#do { Start-Sleep -Milliseconds 100 } until ((Get-Job -Id $ScanOnJob.Id).State -eq 'Completed')
#Receive-Job -Id $ScanOnJob.Id
#Remove-Job -Id $ScanOnJob.Id
Start-Sleep -Seconds 10
#$ScanOffJob = Start-Job -ScriptBlock {
    "scan off" | bluetoothctl #}
#do { Start-Sleep -Milliseconds 100 } until ((Get-Job -Id $ScanOffJob.Id).State -eq 'Completed')
#Receive-Job -Id $ScanOffJob.Id
#Remove-Job -Id $ScanOffJob.Id

foreach ($MACAddress in (Get-EQ3Thermostats)) 
{ 
    $MACAddress
    Get-EQ3Temperature -MACAddress $MACAddress 
}

#foreach ($MACAddress in (Get-EQ3Thermostats)) { Set-EQ3Temperature -MACAddress $MACAddress -Temperature 22 }
