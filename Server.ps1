function Connect-Tcp()
{
    param(
        [string]$hostname,
        [Int32]$port,
        [string]$Message
    )
     
    try
    {
        $client = New-Object -TypeName System.Net.Sockets.TcpClient -ArgumentList $hostname,$port
        $stream = $client.GetStream()
         
        $buffer = [System.Text.Encoding]::ASCII.GetBytes($Message)
        $stream.Write($buffer, 0, $buffer.Length)
         
        $receiveBuffer = New-Object -TypeName byte[] -ArgumentList $buffer.Length
        $EndLoop = $false
        $Output = @()
        do
        {
            $stream.Read($receiveBuffer, 0, ($receiveBuffer.Length-1)) | Out-Null
            $receivedText = [System.Text.Encoding]::ASCII.GetString($receiveBuffer)
            if ($receivedText -notmatch "!") { $Output += $receivedText }
        } until ($receivedText -match "!") 
        $stream.Close()
        $client.Close()
        $Output
    } Catch [Exception]
    {
        Write-Host "Could not connect to target machine"
    }
}

#
$Port = "3339"
$Hostname = "192.168.50.76"
#Connect-Tcp -hostname $Hostname -port $Port -Message "Set-EQ3Temperature -MACAddress 00:1A:22:10:D0:C3 -Temperature 18"
Connect-Tcp -hostname $Hostname -port $Port -Message "Get-EQ3Temperature -MACAddress 00:1A:22:10:D0:C3"
#Connect-Tcp -hostname $Hostname -port $Port -Message "Get-EQ3Thermostats"
#Connect-Tcp -hostname 192.168.50.76 -port 3339 -Message "quit"
