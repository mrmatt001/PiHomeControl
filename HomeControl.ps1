#git init
#git remote add PiHomeControl https://github.com/mrmatt001/PiHomeControl.git
#git push --set-upstream PiHomeControl master


modprobe btusb
systemctl start bluetooth
$MACAddresses = @()
foreach ($Device in ("devices" | bluetoothctl)) { if ($Device -match 'CC-RT-M-BLE') { if ($Device -match '(?<MACAddress>[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+)') { $MACAddresses += $Matches.MACAddress } } }
$MACAddresses | Select-Object -Unique
foreach ($MACAddress in $MACAddresses)
{
    "info $MACAddress" | bluetoothctl
}
