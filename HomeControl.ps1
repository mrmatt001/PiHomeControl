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
        $PairedStatus = $false
        if ($Line -match 'Paired\:\s+(?<PairedStatus>[a-zA-Z]+)') 
        {
            if ($Matches.PairedStatus -eq 'no') 
            {
                Write-Host ("$MACAddress is not paired") -ForegroundColor Red
                Write-Host ("$MACAddress attempting to pair")
                "pair $MACAddress" | bluetoothctl
                Start-Sleep -Seconds 5
                foreach ($Line in ("info $MACAddress" | bluetoothctl))
                {
                    if ($Line -match 'Paired\:\s+(?<PairedStatus>[a-zA-Z]+)') 
                    {
                        if ($Matches.PairedStatus -eq 'no') 
                        {
                            Write-Host ("$MACAddress could not be paired") -ForegroundColor Red
                        }
                        else 
                        {
                            Write-Host ("$MACAddress is paired") -ForegroundColor Green  
                            $PairedStatus = $true
                        }
                    }
                }
            }
            else 
            {
                Write-Host ("$MACAddress is paired") -ForegroundColor Green
                $PairedStatus = $true
            }
        }
    }
}
systemctl stop bluetooth