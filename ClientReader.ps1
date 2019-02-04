Import-Module /home/pi/PiHomeControl/PiHomeControl.psm1 -Force

modprobe btusb
systemctl start bluetooth

foreach ($MACAddress in (Get-EQ3Thermostats)) 
{ 
    Get-EQ3Temperature -MACAddress $MACAddress 
}

#foreach ($MACAddress in (Get-EQ3Thermostats)) { Set-EQ3Temperature -MACAddress $MACAddress -Temperature 22 }
