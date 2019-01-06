#git init
#git remote add PiHomeControl https://github.com/mrmatt001/PiHomeControl.git
#git push --set-upstream PiHomeControl master


modprobe btusb
systemctl start bluetooth
$MACAddresses = @()
foreach ($Device in ("devices" | bluetoothctl)) { if ($Device -match 'CC-RT-M-BLE') { if ($Device -match '(?<MACAddress>[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+)') { $MACAddresses += $Matches.MACAddress } } }
foreach ($MACAddress in ($MACAddresses | Select-Object -Unique))
{
    $TryAgain = $true
    get-job | Remove-Job -Force
    $ScriptBlock = (gatttool -b $MACAddress --char-write-req  -a "0x0411" -n "03" --listen)
    $JobList = @()
    $Job = (Start-Job -ScriptBlock $ScriptBlock -Name $MACAddress)
    do
    {
        start-sleep -milliseconds 500
        $JobOutput = Get-Job -id $Job.Id | Receive-Job -Keep
    }
    until ($JobOutput -match 'Characteristic')

    $TempOutput = Get-Job -id $Job.ID | Receive-Job
    Get-Job -id $Job.Id | Remove-Job -Force
    foreach ($Line in $TempOutput)
    {
        if ($Line -match 'Notification handle\s+\=\s+\dx\d+\svalue:\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s(?<Temp>[a-zA-Z0-9]+)') 
        { 
            Write-Host ("Temperature: " + [Convert]::ToInt64(($Matches.Temp),16)/2 + "C")
            $TryAgain = $false
        }
    }
    if ($TryAgain)
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
                    get-job | Remove-Job -Force
                    $ScriptBlock = (gatttool -b $MACAddress --char-write-req  -a "0x0411" -n "03" --listen)
                    #$JobList = @()
                    $Job = (Start-Job -ScriptBlock $ScriptBlock -Name $MACAddress)
                    do
                    {
                        start-sleep -milliseconds 500
                        $JobOutput = Get-Job -id $Job.Id | Receive-Job -Keep
                    }
                    until ($JobOutput -match 'Characteristic')

                    $TempOutput = Get-Job -id $Job.ID | Receive-Job
                    Get-Job -id $Job.Id | Remove-Job -Force
                    foreach ($Line in $TempOutput)
                    {
                        if ($Line -match 'Notification handle\s+\=\s+\dx\d+\svalue:\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s(?<Temp>[a-zA-Z0-9]+)') 
                        { 
                            Write-Host ("Temperature: " + [Convert]::ToInt64(($Matches.Temp),16)/2 + "C")
                        }
                    }
                }
            }
        }
    }
}
systemctl stop bluetooth