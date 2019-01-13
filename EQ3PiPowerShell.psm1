function Get-EQ3Temperature
{
    param (
    $MACAddress,
    [Int32]$TimeOut = 30)
    process
    {
        modprobe btusb
        systemctl start bluetooth
        get-job | Remove-Job -Force
        $scriptBlock = [scriptblock]::Create("gatttool -b " + $MACAddress + ' --char-write-req -a "0x0411" -n "03" --listen')
        $Job = (Start-Job -Name $MACAddress -ScriptBlock $scriptBlock -ArgumentList $MACAddress)
        $JobStartTime = (Get-Date)
        do
        {
            start-sleep -milliseconds 500
            $JobOutput = Get-Job -id $Job.Id -ErrorAction SilentlyContinue | Receive-Job -Keep
        }
        until (($JobOutput -match 'Characteristic') -or (((Get-Date).AddSeconds(-$TimeOut) -gt $JobStartTime)))
        
        if ($JobOutput -match 'Characteristic')
        {
            $TempOutput = Get-Job -id $Job.ID | Receive-Job
            $null = Get-Job -id $Job.Id | Remove-Job -Force
            foreach ($Line in $TempOutput)
            {
                if ($Line -match 'Notification handle\s+\=\s+\dx\d+\svalue:\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s(?<Temp>[a-zA-Z0-9]+)') 
                { 
                    return ([Convert]::ToInt64(($Matches.Temp),16)/2)
                }
            }
        }
        else 
        {
            return "Request timed out"    
        }
    }
}

function Get-EQ3Thermostats
{
    modprobe btusb
    systemctl start bluetooth
    $MACAddresses = @()
    foreach ($Device in ("devices" | bluetoothctl)) { if ($Device -match 'CC-RT-M-BLE') { if ($Device -match '(?<MACAddress>[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+)') { $MACAddresses += $Matches.MACAddress } } }
    return ($MACAddresses | Sort-Object -Unique)
}

function Set-EQ3Temperature
{
    param (
        $MACAddress,
        $Temperature,
        [Int32]$TimeOut = 30)
    process
    {
        modprobe btusb
        systemctl start bluetooth
        $Temp2 = $Temperature
        if ($Temperature -match '^(?<TEMPHex>[0-3][0-9]).[5]') { $Temp2 = (([INT32]$Matches.TEMPHex * 2) + 1) }
        if ($Temperature -match '^(?<TEMPHex>[0-3][0-9]).[0]') { $Temp2 = (([INT32]$Matches.TEMPHex * 2)) }
        $TemperatureHex = '{0:x}' -f $Temp2
        $SetTemp = (gatttool -b $MACAddress --char-write-req -a "0x0411" -n "41$TemperatureHex")
    }     
}

function Get-AllowedEQ3Commands
{
    param(
        [STRING]$ReceivedText
    )
    
    if ($receivedText -match '^Set-EQ3Temperature\s-MACAddress\s(?<MACAddress>[a-fA-F0-9:]+)\s-Temperature\s(?<Temperature>[0-3][0-9].[05]+)')
    {
        return "Valid"
    }
    
    if ($receivedText -match '^Get-EQ3Temperature\s-MACAddress\s(?<MACAddress>[a-fA-F0-9:]+)')
    {
        return "Valid"
    }
    
    if ($receivedText -match '^Get-EQ3Thermostats')
    {
        return "Valid"
    }
}

