#git init
#git remote add PiHomeControl https://github.com/mrmatt001/PiHomeControl.git
#git push --set-upstream PiHomeControl master
Import-Module /home/pi/PiHomeControl/EQ3PiPowerShell.psm1

modprobe btusb
systemctl start bluetooth

#foreach ($MACAddress in (Get-EQ3Thermostats)) { Get-EQ3Temperature -MACAddress $MACAddress }

#foreach ($MACAddress in (Get-EQ3Thermostats)) { Set-EQ3Temperature -MACAddress $MACAddress -Temperature 22 }

function Listen-Tcp()
{
    param(
        [Int32] $port
    )
    $server = New-Object -TypeName System.Net.Sockets.TcpListener -ArgumentList @([System.Net.IPAddress]::Any, $port)
    $server.Start()
    $clientSocket = $server.AcceptSocket()
    $buffer = New-Object -TypeName byte[] -ArgumentList 100
    $clientSocket.Receive($buffer) | Out-Null 
    $receivedText = [System.Text.Encoding]::ASCII.GetString($buffer)
    if ($receivedText -eq 'quit') 
    { 
        return "quit" 
    }
    else 
    {
        $ReturnCommand = Get-AllowedEQ3Commands
        if ($ReturnCommand -eq 'valid')  
        { 
            Write-Host "Received valid command: $ReceivedText" -ForegroundColor Green
        }
        else 
        {
            Write-Host "Invalid command received" -ForegroundColor Red    
        }
    }
    $clientSocket.Close()
    $server.Stop()
}

$Port = 3339
Clear-Host
Write-Host "Listening on port: $Port"
do { $ListenTCP = (Listen-Tcp -port $Port) } until ($ListenTCP -eq 'quit')
