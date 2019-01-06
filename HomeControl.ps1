#git init
#git remote add PiHomeControl https://github.com/mrmatt001/PiHomeControl.git
#git push --set-upstream PiHomeControl master


modprobe btusb
systemctl start bluetooth
$MACAddresses = @()
foreach ($Device in ("devices" | bluetoothctl)) { if ($Device -match 'CC-RT-M-BLE') { if ($Device -match '(?<MACAddress>[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+)') { $MACAddresses += $Matches.MACAddress } } }
foreach ($MACAddress in ($MACAddresses | Select-Object -Unique))
{
    foreach ($Line in ("info $MACAddress" | bluetoothctl))
    {
        if ($Line -match 'Paired\:\s+(?<PairedStatus>[a-zA-Z]+') 
        {
            Write-Host ("$MACAddress paired: " + $Matches.PairedStatus)
        }
    }
}
systemctl stop bluetooth