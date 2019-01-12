#git init
#git remote add PiHomeControl https://github.com/mrmatt001/PiHomeControl.git
#git push --set-upstream PiHomeControl master
Import-Module .\EQ3PiPowerShell.psm1

modprobe btusb
systemctl start bluetooth

foreach ($MACAddress in (Get-EQ3Thermostats)) { Get-EQ3Temperature -MACAddress $MACAddress }

foreach ($MACAddress in (Get-EQ3Thermostats)) { Set-EQ3Temperature -MACAddress $MACAddress -Temperature 22 }


systemctl stop bluetooth